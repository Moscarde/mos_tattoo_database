# 🎨 Tattoo Sales Database

Banco de dados PostgreSQL para análise de vendas de insumos de tatuagem, containerizado com Docker.

## 🚀 Como Rodar

A maneira mais simples é utilizar o script gerenciador `manage.sh`.

### Pré-requisitos
*   Docker e Docker Compose

### Passos
1.  **Inicie o banco de dados:**
    ```bash
    chmod +x manage.sh
    ./manage.sh up
    ```
    *Isso cria o arquivo `.env` automaticamente e sobe o container na porta **5433**.*

2.  **Gere dados históricos (Opcional):**
    ```bash
    ./manage.sh setup
    ```
    *Popula o banco com cerca de 500.000 vendas retroativas.*

3.  **Geração em tempo real (Opcional):**
    ```bash
    ./manage.sh generate
    ```
    *Inicia um gerador contínuo de novas vendas.*

---

## 🔧 Variáveis de Ambiente

As configurações padrão são definidas no arquivo `.env` gerado.

| Variável | Valor Padrão | Descrição |
| :--- | :--- | :--- |
| `POSTGRES_USER` | `tattoo_user` | Usuário do banco |
| `POSTGRES_PASSWORD` | `tattoo_pass` | Senha do banco |
| `POSTGRES_DB` | `tattoo_sales_db` | Nome do banco de dados |
| `POSTGRES_PORT` | `5433` | Porta exposta no host |

---

## 🗂️ Esquema de Dados (Schema)

O banco segue um modelo relacional simples de vendas.

| Tabela | Descrição |
| :--- | :--- |
| **`units`** | Unidades físicas de venda (lojas/filiais). |
| **`sellers`** | Vendedores associados a uma unidade específica. |
| **`products`** | Catálogo de produtos (preço, categoria, etc). |
| **`sales`** | Registro das transações (data, valor total, status). |
| **`sale_items`** | Itens individuais de cada venda (quantidade, preço unitário). |

> **Views Úteis:**
> *   `v_sales_complete`: Visão desnormalizada das vendas com dados da unidade e vendedor.
> *   `v_sale_items_detail`: Detalhes dos itens com nome do produto e categoria.

---

## 🌱 Dados Fictícios (Seeding)

O projeto utiliza uma abordagem híbrida para popular o banco:

1.  **Dados Estáticos (SQL):**
    *   As tabelas são criadas e as unidades/vendedores iniciais são inseridos via `schema.sql`.
    *   Produtos iniciais são carregados via `seed_products.sql`.

2.  **Dados Dinâmicos (Python):**
    *   O comando `./manage.sh setup` executa um script Python (`generate_historical_data.py`) que cria um histórico de vendas realista.
    *   O comando `./manage.sh generate` simula vendas em tempo real (`generate_realtime_sales.py`).
