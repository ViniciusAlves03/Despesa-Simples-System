#!/usr/bin/env bash
# Define where to store the generated certs and metadata.
DIR="$(pwd)/.certs"

SERVICES_NAMES=api-gateway,web-app,account,budgets,categories,expenses,incomes,notification

rm -rf $DIR
mkdir -p $DIR

# Create the openssl configuration file. This is used for both generating
# the certificate as well as for specifying the extensions. It aims in favor
# of automation, so the DN is encoding and not prompted.
createOpenSSLConfig() {
  cat >"${DIR}/openssl.cnf" <<EOF
  ####################################################################
  [ ca ]
  default_ca = CA_default        # The default ca section

  [ CA_default ]
  default_md  = sha256            # use public key default MD
  preserve    = no                # keep passed DN ordering

  x509_extensions = ca_extensions # The extensions to add to the cert

  email_in_dn = no                # Don't concat the email in the DN
  copy_extensions = copy          # Required to copy SANs from CSR to cert

  ####################################################################
  [ req ]
  default_bits        = 2048
  default_keyfile     = tmp/external.key
  distinguished_name  = ca_distinguished_name
  x509_extensions     = ca_extensions
  string_mask         = utf8only

  ####################################################################
  [ ca_distinguished_name ]
  countryName                    = BR
  stateOrProvinceName            = PB
  localityName                   = Campina Grande
  organizationName               = EXP
  organizationalUnitName         = EXP
  commonName                     = EXP CA

  ####################################################################
  [ ca_extensions ]
  subjectKeyIdentifier = hash
  authorityKeyIdentifier = keyid:always, issuer
  basicConstraints = critical, CA:true
  keyUsage = critical, digitalSignature, nonRepudiation, keyCertSign, cRLSign

  ####################################################################
  [ client_extensions ]
  basicConstraints = CA:false
  keyUsage         = digitalSignature, keyEncipherment
  extendedKeyUsage = clientAuth
  subjectAltName   = @alt_names

  ####################################################################
  [ server_extensions ]
  basicConstraints = CA:false
  keyUsage         = digitalSignature, keyEncipherment
  extendedKeyUsage = serverAuth
  subjectAltName   = @alt_names
  subjectKeyIdentifier = hash
  authorityKeyIdentifier = keyid,issuer

  ####################################################################
  [ client_server_extensions ]
  basicConstraints     = CA:FALSE
  keyUsage             = digitalSignature, keyEncipherment
  extendedKeyUsage     = clientAuth, serverAuth
  subjectKeyIdentifier = hash
  subjectAltName       = @alt_names

  ####################################################################

  [ alt_names ]
  IP.1  = 127.0.0.1
  DNS.1 = localhost
EOF
}
createOpenSSLConfig

# Create the certificate authority (CA). This will be a self-signed CA, and this
# command generates both the private key and the certificate. You may want to
# adjust the number of bits (4096 is a bit more secure, but not supported in all
# places at the time of this publication).
#
# To put a password on the key, remove the -nodes option.
#
# Be sure to update the subject to match your organization.
#
# Generate your CA certificate
openssl req -x509 \
  -config "$DIR/openssl.cnf" \
  -nodes -days 3650 \
  -subj "/O=EXP,CN=EXP CA" \
  -keyout "$DIR/ca.key" \
  -out "$DIR/ca.pem" 2>/dev/null

# Params:
# type (server, client) $1, CN $2, Alt Names $3, filename $4, output $5
generateCerts() {
  # Create destination directory
  mkdir -p $5

  ORG="$2"
  TYPE="server_extensions"

  if [ "$1" = "client" ]; then
    TYPE="client_extensions"
  elif [ "$1" = "client/server" ]; then
    TYPE="client_server_extensions"
  fi

  # Add Subject Alternative Names
  DNS_LIST=$(echo $3 | sed "s/,/ /g")
  NUMBER=3
  for DNS in ${DNS_LIST}; do
    echo "DNS.${NUMBER} = ${DNS}" >>$DIR/openssl.cnf
    NUMBER=$((NUMBER + 1))
  done

  # Generate the private key
  openssl genrsa -out "$5/$4.key" 2>/dev/null

  # Generate a CSR using the configuration and the key just generated. We will
  # give this CSR to our CA to sign.
  openssl req \
    -new -nodes \
    -key "$5/$4.key" \
    -subj "/O=$ORG/CN=EXP" \
    -out "$5/$4.csr" 2>/dev/null

  # Sign the CSR with our CA. This will generate a new certificate that is signed
  # by our CA.
  openssl x509 \
    -req -days 3650 -in "$5/$4.csr" \
    -CA "$DIR/ca.pem" -CAkey "$DIR/ca.key" -CAcreateserial \
    -out "$5/$4.crt" -extfile "$DIR/openssl.cnf" \
    -extensions $TYPE 2>/dev/null

  # Copy CA file to the destination directory
  cp "$DIR/ca.pem" "$5/ca.pem"

  chmod 0644 "$DIR/ca.pem" "$5/$4.key" "$5/$4.crt"

  # Remove unused files
  rm -f $5/*.csr

  createOpenSSLConfig
}

# type (server, client) $1, CN $2, Alt Names $3, filename $4, output $5
generateCertsPostgres() {
  generateCerts $1 $2 $3 $4 $5
}

# Certificates for microservices
SERVICES_ALT_NAMES_POSTGRES="postgres"
SERVICES=$(echo $SERVICES_NAMES | tr "," "\n")
COUNT=${#SERVICES[@]}
for service in ${SERVICES[@]}; do
  SERVICES_ALT_NAMES_POSTGRES+=",postgres-${service}"

  echo "$COUNT - Generating certificates for the \"${service^^}\" Service..."
  generateCerts "server" "$service" "api.localhost" "server" "$DIR/$service"  # Server
  if [ "$service" != "api-gateway" ] && [ "$service" != "web-app" ] && [ "$service" != "registry" ]; then
    generateCerts "client" "$service" "rabbitmq" "rabbitmq" "$DIR/$service" # Client RabbitMQ
    generateCertsPostgres "client" "$service" "postgres,${service}" "postgres" "$DIR/$service" # Client PostgreSQL
	fi

  if [ "$service" = "account" ]; then
    # Create JWT certs
    ssh-keygen -t rsa -P "" -b 2048 -m PEM -f "$DIR/$service/jwt.key"
    ssh-keygen -e -m PEM -f "$DIR/$service/jwt.key" >"$DIR/$service/jwt.key.pub"
    [ -d .certs/web-app ] && cp .certs/account/jwt.key.pub .certs/web-app
    [ -d .certs/api-gateway ] && cp .certs/account/jwt.key.pub .certs/api-gateway
  fi
  COUNT=$((COUNT + 1))
done

# Generate certificates for Postgres
echo "$COUNT - Generating certificates for the \"PostgreSQL Server\"..."
generateCertsPostgres "server" "postgres" $SERVICES_ALT_NAMES_POSTGRES "server" "$DIR/postgres" # Server PostgreSQL

# Generate certificates for RabbitMQ
echo "$((COUNT + 2)) - Generating certificates for the \"RabbitMQ Server\"..."
generateCerts "server" "rabbitmq" "rabbitmq" "server" "$DIR/rabbitmq" # Server RabbitMQ

# (Optional) Remove unused files at the moment
rm -rf $DIR/ca.* $DIR/*.srl $DIR/*.csr $DIR/*.cnf

chmod 755 ${DIR} -R
chmod 600 $(ls $DIR/**/postgres.key) $DIR/postgres/server.key
sudo chown 70:70 $DIR/postgres/server.key
