# 🚀 Quick Start - Tattoo Sales Database

Guia rápido para começar a usar o projeto em **menos de 5 minutos**.

---

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- 2GB de espaço em disco
- Nada mais! ✨

---

## ⚡ Início Rápido (3 passos)

### 1️⃣ Tornar o script executável

```bash
chmod +x manage.sh
```

### 2️⃣ Iniciar o banco de dados

```bash
./manage.sh up
```

Isso vai:
- ✅ Criar arquivo `.env` automaticamente
- ✅ Iniciar PostgreSQL na porta **5433**
- ✅ Criar todas as tabelas e índices
- ✅ Inserir unidades, vendedores e produtos

### 3️⃣ Gerar dados históricos

```bash
./manage.sh setup
```

Isso vai:
- ✅ Gerar ~525.000 vendas dos últimos 365 dias
- ✅ Distribuir vendas entre 5 unidades
- ✅ Calcular datas de entrega realistas
- ⏱️ Duração: ~5-10 minutos

---

## 🎯 Comandos Essenciais

### Ver estatísticas do banco

```bash
./manage.sh stats
```

Mostra:
- Total de vendas, produtos, unidades
- Faturamento total e ticket médio
- Entregas no prazo vs pendentes
- Vendas das últimas 24 horas

### Iniciar geração contínua (1 venda/min)

```bash
./manage.sh generate
```

### Acompanhar vendas sendo geradas

```bash
./manage.sh logs-gen
```

Pressione `Ctrl+C` para sair dos logs

### Acessar o banco de dados

```bash
./manage.sh db
```

Comandos úteis dentro do psql:
- `\dt` - Listar tabelas
- `\d sales` - Ver estrutura da tabela sales
- `\q` - Sair

---

## 📊 Queries Prontas

### Total de vendas

```sql
SELECT COUNT(*) FROM sales;
```

### Faturamento por unidade (últimos 30 dias)

```sql
SELECT 
    u.name AS unidade,
    COUNT(s.id) AS total_vendas,
    SUM(CASE WHEN NOT s.canceled THEN s.total_value ELSE 0 END) AS faturamento
FROM sales s
JOIN units u ON s.unit_id = u.id
WHERE s.sold_at >= NOW() - INTERVAL '30 days'
GROUP BY u.name
ORDER BY faturamento DESC;
```

### Entregas no prazo vs atrasadas

```sql
SELECT 
    COUNT(CASE 
        WHEN EXTRACT(DAY FROM (delivered_at - sold_at)) <= expected_delivery_days 
        THEN 1 
    END) AS no_prazo,
    COUNT(CASE 
        WHEN EXTRACT(DAY FROM (delivered_at - sold_at)) > expected_delivery_days 
        THEN 1 
    END) AS atrasadas,
    ROUND(100.0 * COUNT(CASE 
        WHEN EXTRACT(DAY FROM (delivered_at - sold_at)) <= expected_delivery_days 
        THEN 1 
    END) / COUNT(*), 2) AS percentual_no_prazo
FROM sales
WHERE delivered_at IS NOT NULL
  AND NOT canceled;
```

---

## 🔧 Comandos de Gerenciamento

### Ver todos os comandos disponíveis

```bash
./manage.sh
```

### Parar tudo

```bash
./manage.sh down
```

### Reiniciar banco

```bash
./manage.sh restart
```

### Ver status dos containers

```bash
./manage.sh status
```

### Fazer backup

```bash
./manage.sh backup
```

Cria um arquivo `backup_YYYYMMDD_HHMMSS.sql`

### Restaurar backup

```bash
./manage.sh restore backup_20260214_123456.sql
```

---

## 🧹 Limpeza e Reset

### Limpar tudo (apaga dados)

```bash
./manage.sh clean
```

⚠️ **CUIDADO:** Isso apaga todos os dados!

### Reset completo (limpa e reinicia)

```bash
./manage.sh reset
```

Útil para começar do zero

---

## 🐛 Troubleshooting

### Porta 5433 já está em uso

Edite o arquivo `.env`:

```bash
POSTGRES_PORT=5434
```

Depois reinicie:

```bash
./manage.sh down
./manage.sh up
```

### Container não inicia

```bash
./manage.sh logs-db
```

Verifique os erros e tente:

```bash
./manage.sh reset
```

### Gerador travou

```bash
./manage.sh restart-gen
./manage.sh logs-gen
```

---

## 📱 Conectar de um Backend Django

### 1. Instalar driver

```bash
pip install psycopg2-binary
```

### 2. Configurar settings.py

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'tattoo_sales_db',
        'USER': 'tattoo_user',
        'PASSWORD': 'tattoo_password_2026',
        'HOST': 'localhost',
        'PORT': '5433',
    }
}
```

### 3. Criar models

Use `managed = False` para não deixar Django gerenciar as tabelas:

```python
class Sale(models.Model):
    # ... campos
    class Meta:
        db_table = 'sales'
        managed = False
```

---

## 🎓 Próximos Passos

1. ✅ Explore o banco com `./manage.sh db`
2. ✅ Veja queries de exemplo no [README.md](README.md#exemplos-de-queries)
3. ✅ Conecte seu backend Django/Flask
4. ✅ Crie dashboards incríveis! 📊

---

## 📚 Documentação Completa

Para mais detalhes, consulte o [README.md](README.md) completo.

---

## 💡 Dicas

- Use `./manage.sh stats` frequentemente para monitorar
- Deixe o gerador rodando para ter dados em tempo real
- Faça backups antes de experimentos arriscados
- O script `manage.sh` é seu melhor amigo! 🤖

---

**Feito com ❤️ para análise de dados e BI**
