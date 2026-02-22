# Template-Based BI Distribution | Sample Database (Demo)

Banco de dados PostgreSQL de demonstração do ecossistema [Template-Based BI Distribution](https://github.com/Moscarde/Template-Based-BI-Distribution), containerizado com Docker.

Este repositório fornece um conjunto de dados fictícios para validar a engine de templates em funcionamento. A temática escolhida — uma rede de unidades de venda de insumos — foi definida para viabilizar uma exploração rica de métricas, categorias e granularidades nos dashboards, sem nenhuma relação com o domínio de aplicação da engine.

> 🔗 **Repositório Central**: Para entender o contexto completo da arquitetura, acesse o [repositório principal](https://github.com/Moscarde/Template-Based-BI-Distribution).

---

## 🚀 Como Rodar

### Opção 1: Usando o script gerenciador (Recomendado)

A maneira mais simples é utilizar o script gerenciador `manage.sh`.

**Pré-requisitos:** Docker e Docker Compose.

1. **Inicie o banco de dados:**

```bash
chmod +x manage.sh
./manage.sh up
```

*Isso cria o arquivo `.env` automaticamente e sobe o container na porta **5433**.*

2. **Gere dados históricos (Opcional):**

```bash
./manage.sh setup
```

*Popula o banco com cerca de 500.000 registros de vendas retroativas.*

3. **Geração em tempo real (Opcional):**

```bash
./manage.sh generate
```

*Inicia um gerador contínuo de novos registros, simulando operação ao vivo.*

---

### Opção 2: Usando Docker Compose diretamente

Caso prefira não utilizar o script gerenciador, você pode executar os comandos do Docker Compose manualmente.

**Pré-requisitos:** Docker e Docker Compose.

1. **Configure o ambiente:**

```bash
cp .env.example .env
```

2. **Inicie o banco de dados:**

```bash
docker compose up -d postgres
```

3. **Gere dados históricos (Opcional):**

Para popular o banco com dados retroativos, utilize o perfil de setup:

```bash
docker compose --profile setup up historical_data
```

4. **Geração em tempo real (Opcional):**

Para iniciar o gerador de vendas contínuas em background:

```bash
docker compose up -d data_generator
```

Para parar o gerador:

```bash
docker compose stop data_generator
```

---

## 🔧 Variáveis de Ambiente

As configurações padrão são definidas no arquivo `.env` gerado automaticamente.

| Variável | Valor Padrão | Descrição |
| :--- | :--- | :--- |
| `POSTGRES_USER` | `demo_user` | Usuário do banco |
| `POSTGRES_PASSWORD` | `demo_pass` | Senha do banco |
| `POSTGRES_DB` | `demo_db` | Nome do banco de dados |
| `POSTGRES_PORT` | `5433` | Porta exposta no host |

---

## 🗂️ Esquema de Dados (Schema)

O banco segue um modelo relacional de vendas multi-unidade, desenhado para exercitar os recursos de isolamento e agregação da engine.

| Tabela | Descrição |
| :--- | :--- |
| **`units`** | Unidades de negócio (filiais/lojas) — base do isolamento multi-tenant. |
| **`sellers`** | Vendedores associados a cada unidade. |
| **`products`** | Catálogo de produtos (preço, categoria, etc). |
| **`sales`** | Registro das transações (data, valor total, status). |
| **`sale_items`** | Itens individuais de cada venda (quantidade, preço unitário). |

**Views Úteis:**
- `v_sales_complete` — Visão desnormalizada das vendas com dados da unidade e vendedor.
- `v_sale_items_detail` — Detalhes dos itens com nome do produto e categoria.

---

## 🌱 Estratégia de Seeding

O projeto utiliza uma abordagem híbrida para popular o banco:

**Dados Estáticos (SQL):** As tabelas são criadas e as unidades, vendedores e produtos iniciais são inseridos via `schema.sql` e `seed_products.sql`.

**Dados Dinâmicos (Python):** O comando `./manage.sh setup` executa um script Python (`generate_historical_data.py`) que gera um histórico de vendas realista. O comando `./manage.sh generate` simula operação contínua em tempo real (`generate_realtime_sales.py`).