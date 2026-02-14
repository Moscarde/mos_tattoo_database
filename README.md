# 🎨 Tattoo Sales Database

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![Python](https://img.shields.io/badge/Python-3.11-green.svg)](https://www.python.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)](https://www.docker.com/)

Banco de dados PostgreSQL dockerizado com simulação realista de vendas de uma fábrica de insumos para tatuagem. Inclui dados históricos do último ano e geração contínua de novas vendas para alimentar dashboards de BI.

---

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Tecnologias](#tecnologias)
- [Modelo de Dados](#modelo-de-dados)
- [Início Rápido](#início-rápido)
- [Scripts Disponíveis](#scripts-disponíveis)
- [Exemplos de Queries](#exemplos-de-queries)
- [Integração com Django](#integração-com-django)
- [Estrutura do Projeto](#estrutura-do-projeto)

---

## 🎯 Sobre o Projeto

Este projeto fornece uma infraestrutura completa para simulação de dados de vendas de insumos para tatuagem:

- **5 unidades** de venda distribuídas pelo Brasil
- **12 vendedores** ativos
- **50 produtos** realistas em 7 categorias
- **~525.000 vendas** históricas (últimos 365 dias)
- **Geração contínua** de 1 venda por minuto

### 🎲 Regras de Simulação

- Distribuição desigual entre unidades (SP Centro = 30%, RJ = 25%, BH = 20%, CT = 15%, POA = 10%)
- 1 a 5 itens por venda
- Taxa de cancelamento: 3% a 8%
- Tempo de entrega: 1 a 15 dias
- Variação de preço: -10% a +5% do preço base

---

## 🛠 Tecnologias

- **PostgreSQL 15** - Banco de dados relacional
- **Docker Compose** - Orquestração de containers
- **Python 3.11** - Scripts de geração de dados
- **psycopg2** - Driver PostgreSQL para Python
- **Faker** - Geração de dados realistas

---

## 📊 Modelo de Dados

### Tabelas

#### `units` - Unidades de Venda
```sql
id              SERIAL PRIMARY KEY
name            VARCHAR(100)
code            VARCHAR(20) UNIQUE
active          BOOLEAN
created_at      TIMESTAMP
updated_at      TIMESTAMP
```

#### `sellers` - Vendedores
```sql
id              SERIAL PRIMARY KEY
name            VARCHAR(100)
unit_id         INTEGER → units(id)
active          BOOLEAN
created_at      TIMESTAMP
updated_at      TIMESTAMP
```

#### `products` - Produtos
```sql
id              SERIAL PRIMARY KEY
name            VARCHAR(200)
category        VARCHAR(50)
price           DECIMAL(10,2)
active          BOOLEAN
created_at      TIMESTAMP
updated_at      TIMESTAMP
```

**Categorias:**
- Máquinas (6 produtos)
- Agulhas / Cartuchos (9 produtos)
- Fontes (4 produtos)
- Tintas (7 produtos)
- Cabos e grips (6 produtos)
- Kits (4 produtos)
- Higienização (8 produtos)

#### `sales` - Vendas
```sql
id                      SERIAL PRIMARY KEY
sold_at                 TIMESTAMP
unit_id                 INTEGER → units(id)
seller_id               INTEGER → sellers(id)
total_value             DECIMAL(10,2)
expected_delivery_days  INTEGER (dias esperados para entrega)
delivered_at            TIMESTAMP (data real da entrega)
canceled                BOOLEAN
created_at              TIMESTAMP
```

**Campos de Entrega:**
- `expected_delivery_days`: Prazo prometido ao cliente (1-15 dias)
- `delivered_at`: Data/hora em que a entrega foi realizada
- KPI: Compare `delivered_at - sold_at` com `expected_delivery_days` para calcular entregas no prazo

#### `sale_items` - Itens da Venda
```sql
id              SERIAL PRIMARY KEY
sale_id         INTEGER → sales(id)
product_id      INTEGER → products(id)
quantity        INTEGER
unit_price      DECIMAL(10,2)
created_at      TIMESTAMP
```

### Views

- **`v_sales_complete`** - Vendas com informações de unidade e vendedor
- **`v_sale_items_detail`** - Itens com detalhes do produto

---

## 🚀 Início Rápido

### 1. Pré-requisitos

- **Docker e Docker Compose** instalados
- **2GB** de espaço em disco disponível
- **Nenhuma dependência local** (tudo roda em containers!)

### 2. Clone e Configure

```bash
# Clone o repositório
git clone <seu-repositorio>
cd mos_tattoo_database

# Copie o arquivo de ambiente
cp .env.example .env
```

> **Nota:** O projeto usa a porta **5433** para evitar conflitos com PostgreSQL local.

### 3. Inicie o Banco de Dados

```bash
# Inicia o PostgreSQL
docker compose up -d postgres

# Acompanhe a inicialização (Ctrl+C para sair)
docker compose logs -f postgres
```

Aguarde até ver: `database system is ready to accept connections`

### 4. Gere Dados Históricos (Uma Vez)

```bash
# Executa o gerador de dados históricos via Docker
docker compose --profile setup up historical_data

# Acompanhe o progresso
docker compose logs -f historical_data
```

**Tempo estimado:** 5-10 minutos para gerar ~525.000 vendas

> Este comando usa um **profile** do Docker Compose, então só roda quando solicitado.

### 5. Inicie a Geração Contínua

```bash
# Inicia o gerador em tempo real
docker compose up -d data_generator

# Visualize as vendas sendo geradas
docker compose logs -f data_generator
```

### 6. Verifique os Dados

```bash
# Conecte ao banco
docker compose exec postgres psql -U tattoo_user -d tattoo_sales_db

# Execute queries de teste
SELECT COUNT(*) FROM sales;
SELECT * FROM v_sales_complete LIMIT 10;

# Para sair do psql
\q
```

---

## 📜 Scripts Disponíveis

### Geração de Dados Históricos (Docker)

```bash
# Executa uma vez via Docker Compose
docker compose --profile setup up historical_data

# Acompanha os logs
docker compose logs -f historical_data
```

**Características:**
- Gera ~525.000 vendas (últimos 365 dias)
- Distribui vendas entre unidades com pesos diferentes
- Insere em lotes de 1000 para performance
- Mostra progresso e estatísticas finais

### Geração em Tempo Real (Docker)

```bash
# Inicia como serviço contínuo
docker compose up -d data_generator

# Visualiza as vendas sendo geradas
docker compose logs -f data_generator

# Para o gerador
docker compose stop data_generator
```

**Características:**
- Insere 1 venda a cada 60 segundos
- Usa timestamp atual
- Exibe detalhes de cada venda
- Estatísticas a cada 10 vendas
- Reinicia automaticamente se cair

### 🔧 Execução Local (Opcional)

Se você **realmente** quiser rodar os scripts localmente:

```bash
# Criar arquivo .env na raiz do projeto
cp .env.example .env

# Instalar dependências
cd scripts
pip install -r requirements.txt

# Dados históricos
python generate_historical_data.py

# Tempo real
python generate_realtime_sales.py
```

> ⚠️ **Atenção:** Use a porta **5433** no DATABASE_URL se o PostgreSQL estiver no Docker.

---

## 🔍 Exemplos de Queries

### Faturamento por Unidade (Últimos 30 dias)

```sql
SELECT 
    u.name AS unidade,
    COUNT(s.id) AS total_vendas,
    COUNT(CASE WHEN s.canceled THEN 1 END) AS canceladas,
    SUM(CASE WHEN NOT s.canceled THEN s.total_value ELSE 0 END) AS faturamento,
    ROUND(AVG(CASE WHEN NOT s.canceled THEN s.total_value END), 2) AS ticket_medio
FROM sales s
JOIN units u ON s.unit_id = u.id
WHERE s.sold_at >= NOW() - INTERVAL '30 days'
GROUP BY u.id, u.name
ORDER BY faturamento DESC;
```

### Top 10 Vendedores do Mês

```sql
SELECT 
    sel.name AS vendedor,
    u.name AS unidade,
    COUNT(s.id) AS total_vendas,
    SUM(CASE WHEN NOT s.canceled THEN s.total_value ELSE 0 END) AS faturamento
FROM sales s
JOIN sellers sel ON s.seller_id = sel.id
JOIN units u ON sel.unit_id = u.id
WHERE s.sold_at >= DATE_TRUNC('month', NOW())
  AND NOT s.canceled
GROUP BY sel.id, sel.name, u.name
ORDER BY faturamento DESC
LIMIT 10;
```

### Produtos Mais Vendidos

```sql
SELECT 
    p.name AS produto,
    p.category AS categoria,
    SUM(si.quantity) AS quantidade_vendida,
    SUM(si.quantity * si.unit_price) AS faturamento_total,
    COUNT(DISTINCT si.sale_id) AS numero_vendas
FROM sale_items si
JOIN products p ON si.product_id = p.id
JOIN sales s ON si.sale_id = s.id
WHERE s.sold_at >= NOW() - INTERVAL '30 days'
  AND NOT s.canceled
GROUP BY p.id, p.name, p.category
ORDER BY quantidade_vendida DESC
LIMIT 20;
```

### Faturamento por Categoria

```sql
SELECT 
    p.category AS categoria,
    COUNT(DISTINCT s.id) AS vendas,
    SUM(si.quantity) AS unidades_vendidas,
    SUM(si.quantity * si.unit_price) AS faturamento
FROM sale_items si
JOIN products p ON si.product_id = p.id
JOIN sales s ON si.sale_id = s.id
WHERE s.sold_at >= NOW() - INTERVAL '90 days'
  AND NOT s.canceled
GROUP BY p.category
ORDER BY faturamento DESC;
```

### Análise de Cancelamentos

```sql
SELECT 
    u.name AS unidade,
    COUNT(*) AS total_vendas,
    SUM(CASE WHEN canceled THEN 1 ELSE 0 END) AS canceladas,
    ROUND(100.0 * SUM(CASE WHEN canceled THEN 1 ELSE 0 END) / COUNT(*), 2) AS taxa_cancelamento
FROM sales s
JOIN units u ON s.unit_id = u.id
WHERE s.sold_at >= NOW() - INTERVAL '30 days'
GROUP BY u.id, u.name
ORDER BY taxa_cancelamento DESC;
```

### Análise de Performance de Entregas por Unidade

```sql
SELECT 
    u.name AS unidade,
    COUNT(*) AS total_entregas,
    ROUND(AVG(s.expected_delivery_days), 1) AS prazo_medio_esperado,
    ROUND(AVG(EXTRACT(DAY FROM (s.delivered_at - s.sold_at))), 1) AS prazo_medio_real,
    COUNT(CASE 
        WHEN EXTRACT(DAY FROM (s.delivered_at - s.sold_at)) <= s.expected_delivery_days 
        THEN 1 
    END) AS entregas_no_prazo,
    ROUND(100.0 * COUNT(CASE 
        WHEN EXTRACT(DAY FROM (s.delivered_at - s.sold_at)) <= s.expected_delivery_days 
        THEN 1 
    END) / COUNT(*), 2) AS percentual_no_prazo
FROM sales s
JOIN units u ON s.unit_id = u.id
WHERE s.sold_at >= NOW() - INTERVAL '30 days'
  AND NOT s.canceled
  AND s.delivered_at IS NOT NULL
GROUP BY u.id, u.name
ORDER BY percentual_no_prazo DESC;
```

### Entregas Atrasadas

```sql
SELECT 
    s.id,
    s.sold_at,
    s.delivered_at,
    u.name AS unidade,
    sel.name AS vendedor,
    s.expected_delivery_days AS prazo_esperado,
    EXTRACT(DAY FROM (s.delivered_at - s.sold_at)) AS dias_reais,
    EXTRACT(DAY FROM (s.delivered_at - s.sold_at)) - s.expected_delivery_days AS dias_atraso,
    s.total_value
FROM sales s
JOIN units u ON s.unit_id = u.id
JOIN sellers sel ON s.seller_id = sel.id
WHERE s.sold_at >= NOW() - INTERVAL '30 days'
  AND NOT s.canceled
  AND s.delivered_at IS NOT NULL
  AND EXTRACT(DAY FROM (s.delivered_at - s.sold_at)) > s.expected_delivery_days
ORDER BY dias_atraso DESC
LIMIT 20;
```

### Evolução de Vendas (Diária)

```sql
SELECT 
    DATE(sold_at) AS data,
    COUNT(*) AS total_vendas,
    SUM(CASE WHEN NOT canceled THEN total_value ELSE 0 END) AS faturamento,
    ROUND(AVG(CASE WHEN NOT canceled THEN total_value END), 2) AS ticket_medio
FROM sales
WHERE sold_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(sold_at)
ORDER BY data DESC;
```

### Análise de Itens por Venda

```sql
SELECT 
    num_items,
    COUNT(*) AS vendas,
    ROUND(AVG(total_value), 2) AS ticket_medio,
    SUM(CASE WHEN NOT canceled THEN total_value ELSE 0 END) AS faturamento
FROM (
    SELECT 
        s.id,
        COUNT(si.id) AS num_items,
        s.total_value,
        s.canceled
    FROM sales s
    JOIN sale_items si ON s.id = si.sale_id
    WHERE s.sold_at >= NOW() - INTERVAL '30 days'
    GROUP BY s.id, s.total_value, s.canceled
) AS vendas_com_itens
GROUP BY num_items
ORDER BY num_items;
```

---

## 📁 Estrutura do Projeto

```
mos_tattoo_database/
├── docker-compose.yml          # Orquestração dos containers
├── .env.example                # Exemplo de variáveis de ambiente
├── .gitignore                  # Arquivos ignorados pelo git
├── README.md                   # Este arquivo
│
├── sql/                        # Scripts SQL
│   ├── schema.sql              # Definição das tabelas
│   └── seed_products.sql       # Seed de produtos iniciais
│
├── scripts/                    # Scripts Python
│   ├── Dockerfile              # Imagem para o gerador
│   ├── requirements.txt        # Dependências Python
│   ├── generate_historical_data.py    # Gerador de dados históricos
│   └── generate_realtime_sales.py     # Gerador em tempo real
│
└── data/                       # Volume persistente do PostgreSQL (ignorado)
```

---

## 🔧 Comandos Úteis

### Docker

```bash
# Iniciar todos os serviços (banco + gerador contínuo)
docker compose up -d

# Iniciar apenas o banco
docker compose up -d postgres

# Gerar dados históricos (primeira vez)
docker compose --profile setup up historical_data

# Parar todos os serviços
docker compose down

# Ver logs de todos os serviços
docker compose logs -f

# Ver logs apenas do banco
docker compose logs -f postgres

# Ver logs apenas do gerador contínuo
docker compose logs -f data_generator

# Reiniciar o gerador
docker compose restart data_generator

# Verificar status dos containers
docker compose ps

# Acessar o banco via psql
docker compose exec postgres psql -U tattoo_user -d tattoo_sales_db
```

### Backup e Restore

```bash
# Fazer backup
docker compose exec postgres pg_dump -U tattoo_user tattoo_sales_db > backup.sql

# Restaurar backup
docker compose exec -T postgres psql -U tattoo_user tattoo_sales_db < backup.sql

# Backup apenas do schema
docker compose exec postgres pg_dump -U tattoo_user --schema-only tattoo_sales_db > schema_backup.sql

# Backup apenas dos dados
docker compose exec postgres pg_dump -U tattoo_user --data-only tattoo_sales_db > data_backup.sql
```

### Limpeza

```bash
# Parar todos os containers
docker compose down

# Parar e remover volumes (apaga todos os dados!)
docker compose down -v

# Remover diretório de dados localmente
rm -rf data/

# Reiniciar do zero
docker compose down -v
rm -rf data/
docker compose up -d postgres
docker compose --profile setup up historical_data
```

### Troubleshooting

#### Porta 5432 já está em uso

O projeto usa a porta **5433** por padrão. Se ainda houver conflito:

```bash
# Edite o arquivo .env e mude POSTGRES_PORT
POSTGRES_PORT=5434  # ou outra porta livre
```

#### Container não inicia

```bash
# Veja os logs de erro
docker compose logs postgres

# Force rebuild da imagem
docker compose build --no-cache
docker compose up -d
```

#### Dados históricos não foram gerados

```bash
# Execute novamente o gerador
docker compose --profile setup up historical_data

# Se falhar, veja os logs
docker compose logs historical_data
```

---

## 📈 Métricas de Performance

- **Inserção em lote:** ~5.000 vendas/segundo
- **Geração histórica:** ~525.000 vendas em 5-10 minutos
- **Tamanho do banco (1 ano):** ~200-300 MB
- **Queries típicas:** < 100ms com índices

---

## 👨‍💻 Autor

**Moscarde**

- GitHub: [@moscarde](https://github.com/moscarde)

