# Despesa Simples - Orquestrador (Docker Compose)

![Kong](https://img.shields.io/badge/kong-%23003459.svg?style=for-the-badge&logo=kong&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/postgresql-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-%234ea94b.svg?style=for-the-badge&logo=mongodb&logoColor=white)
![RabbitMQ](https://img.shields.io/badge/Rabbitmq-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/docker--compose-%232496ED?style=for-the-badge&logo=docker&logoColor=white)

Este é o repositório central do sistema **Despesa Simples**. Ele é responsável por orquestrar e executar todos os serviços em um ambiente de desenvolvimento local usando **Docker Compose**.

Este repositório utiliza **Git Submodules** para referenciar o código-fonte de cada microsserviço individual, permitindo que todo o sistema seja construído e executado com um único comando.

Atualmente, os microsserviços disponíveis são: [`Account`](https://github.com/ViniciusAlves03/DS-account), [`Analytics`](https://github.com/ViniciusAlves03/DS-analytics), [`API-Gateway`](https://github.com/ViniciusAlves03/DS-api-gateway), [`Budgets`](https://github.com/ViniciusAlves03/DS-budgets), [`Categories`](https://github.com/ViniciusAlves03/DS-categories), [`Expenses`](https://github.com/ViniciusAlves03/DS-expenses), [`Incomes`](https://github.com/ViniciusAlves03/DS-incomes) e [`Notification`](https://github.com/ViniciusAlves03/DS-notification).

## ✨ Principais Funcionalidades

* **Orquestração de Múltiplos Serviços:** Define e gerencia o ciclo de vida de todos os microsserviços e seus *backing services* (bancos de dados, mensageria).
* **Ambiente de Desenvolvimento Unificado:** Permite que toda a pilha de tecnologia (API Gateway, microsserviços e bancos de dados/serviços de infra) seja iniciada com `docker-compose up`.
* **Gerenciamento de Submódulos:** Centraliza as referências para todos os repositórios de microsserviços.
* **Infraestrutura como Código:** O arquivo `docker-compose.yml` define toda a infraestrutura necessária, incluindo Kong, PostgreSQL (para o Kong), MongoDB (para os serviços) e RabbitMQ.
* **Segurança Local:** Inclui um script para gerar certificados autoassinados, permitindo que os serviços se comuniquem via HTTPS localmente.

## 🚀 Tecnologias Utilizadas

* **Orquestração:** Docker, Docker Compose
* **API Gateway:** Kong
* **Bancos de Dados:** PostgreSQL (para Kong), MongoDB (para microsserviços)
* **Mensageria:** RabbitMQ
* **Gerenciamento de Código:** Git Submodules
* **Scripting:** Shell Script

## 📋 Pré-requisitos

Para executar este projeto localmente, você precisará ter os seguintes serviços instalados:

* Git
* Docker (v20.x ou superior)
* Docker Compose (v2.x ou superior)
* `openssl` (necessário para executar o script de geração de certificados)

## ⚙️ Instalação e Execução

Este repositório utiliza **Git Submodules**. Siga atentamente as instruções de clone.

1.  **Clone o repositório (Recursive):**
    Use o comando `--recursive` para clonar o repositório e inicializar todos os submódulos de uma só vez.
    ```bash
    git clone --recursive https://github.com/ViniciusAlves03/Despesa-Simples-System.git Despesa-Simples-System
    cd Despesa-Simples-System
    ```
    *Se você já clonou sem o `--recursive`, rode `git submodule init` seguido de `git submodule update`.*

2.  **Gere os Certificados Locais:**
    Este passo é **obrigatório** para a comunicação entre os serviços e o Kong.
    ```bash
    ./create-self-signed-certs.sh
    ```

3.  **Configure as variáveis de ambiente:**
    Crie um arquivo `.env` na raiz do projeto, baseado no `.env.example`.
    ```bash
    cp .env.example .env
    ```
    *Revise o arquivo `.env` e ajuste as senhas conforme necessário.*

4.  **Construa e Inicie os Contêineres:**
    Este comando irá construir as imagens de todos os microsserviços e iniciar toda a pilha.
    ```bash
    docker-compose up --build
    ```

5.  **Acessando os Serviços:**
    Após a inicialização, os seguintes pontos estarão disponíveis:
    * **API Gateway (Kong):** `http://localhost:8000`
    * **RabbitMQ:** `http://localhost:15672`
    * **Serviços (via Gateway):** Conforme definido em `api-gateway/config/declarative/kong.yaml`, geralmente em `http://api.ds.localhost:8000`.

## 🏗️ Estrutura do Projeto

```sh
Despesa-Simples-System/
├── .gitmodules                # Define os repositórios dos microsserviços
├── create-self-signed-certs.sh  # Script para gerar certs SSL locais
├── docker-compose.yml           # Arquivo principal de orquestração
├── .env.example               # Exemplo de variáveis de ambiente
├── .env                       # Variáveis de ambiente (local)
│
├── account/                   # Submódulo: Serviço de Contas (account-service)
├── analytics/                 # Submódulo: Serviço de Relatórios (reports-service)
├── api-gateway/               # Submódulo: Kong API Gateway
├── budgets/                   # Submódulo: Serviço de Orçamentos (budgets-service)
├── categories/                # Submódulo: Serviço de Categorias (categories-service)
├── expenses/                  # Submódulo: Serviço de Despesas (expenses-service)
├── incomes/                   # Submódulo: Serviço de Receitas (incomes-service)
└── notification/              # Submódulo: Serviço de Notificações (notification-service)
```

## 📖 Visão Geral (Serviços Orquestrados)

Este repositório gerencia os seguintes serviços conforme definido no `docker-compose.yml`:

| Serviço | Repositório (Submódulo) | Descrição |
| :--- | :--- | :--- |
| `api-gateway` | `api-gateway` | API Gateway central que gerencia autenticação, autorização (ACL) e roteamento. |
| `account` | `account` | Microsserviço de identidade (usuários, autenticação, JWT). |
| `budgets` | `budgets` | Microsserviço para gerenciar orçamentos (Budgets). |
| `categories` | `categories` | Microsserviço para gerenciar categorias de despesa/receita. |
| `expenses` | `expenses` | Microsserviço para registrar transações de despesa. |
| `incomes` | `incomes` | Microsserviço para registrar transações de receita. |
| `analytics` | `analytics` | Microsserviço que consome outros serviços para gerar relatórios. |
| `notification` | `notification` | Worker de background para envio de e-mails e notificações push. |
| `postgres-api-gateway` | `postgres-api-gateway` | Banco de dados PostgreSQL para o Kong. |
| `mongo` | `mongo` | Banco de dados MongoDB para os microsserviços. |
| `rabbitmq` | `rabbitmq` | Barramento de eventos (Message Broker) para comunicação assíncrona e RPC. |

---

## 🧑‍💻 Autor <a id="autor"></a>

<p align="center">Desenvolvido por Vinícius Alves <strong><a href="https://github.com/ViniciusAlves03">(eu)</a></strong>.</p>

---
