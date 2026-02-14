#!/bin/bash
set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

usage() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🎨 Tattoo Sales Database - Gerenciador"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Uso: ./manage.sh [comando]"
    echo ""
    echo "📦 Comandos Principais:"
    echo "  up          - Inicia o banco de dados"
    echo "  down        - Para todos os containers"
    echo "  restart     - Reinicia o banco de dados"
    echo "  status      - Mostra status dos containers"
    echo ""
    echo "📊 Geração de Dados:"
    echo "  setup       - Gera dados históricos (primeira vez, ~5-10 min)"
    echo "  generate    - Inicia geração contínua (1 venda/min)"
    echo "  stop-gen    - Para o gerador contínuo"
    echo "  restart-gen - Reinicia o gerador contínuo"
    echo ""
    echo "📝 Logs e Monitoramento:"
    echo "  logs        - Exibe logs de todos os serviços"
    echo "  logs-db     - Exibe logs apenas do banco"
    echo "  logs-gen    - Exibe logs do gerador contínuo"
    echo ""
    echo "🗄️ Banco de Dados:"
    echo "  db          - Acessa PostgreSQL via psql"
    echo "  query       - Executa query SQL customizada"
    echo "  stats       - Mostra estatísticas do banco"
    echo ""
    echo "💾 Backup e Restore:"
    echo "  backup      - Cria backup completo"
    echo "  restore     - Restaura backup"
    echo ""
    echo "🧹 Limpeza:"
    echo "  clean       - Remove containers e dados (CUIDADO!)"
    echo "  reset       - Reset completo e reinicia do zero"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

check_env() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  Arquivo .env não encontrado. Criando...${NC}"
        cp .env.example .env
        echo -e "${GREEN}✓ Arquivo .env criado!${NC}"
    fi
}

case "$1" in
    up)
        check_env
        echo -e "${GREEN}🚀 Iniciando banco de dados...${NC}"
        docker compose up -d postgres
        echo ""
        echo -e "${GREEN}✓ Banco iniciado!${NC}"
        echo -e "  Porta: ${YELLOW}5433${NC}"
        echo -e "  Host: ${YELLOW}localhost${NC}"
        echo -e "  Database: ${YELLOW}tattoo_sales_db${NC}"
        echo -e "  User: ${YELLOW}tattoo_user${NC}"
        echo ""
        echo -e "💡 Próximos passos:"
        echo -e "   ${YELLOW}./manage.sh setup${NC}      - Gerar dados históricos"
        echo -e "   ${YELLOW}./manage.sh generate${NC}   - Iniciar geração contínua"
        echo -e "   ${YELLOW}./manage.sh db${NC}         - Acessar banco"
        ;;

    down)
        echo -e "${YELLOW}⏹️  Parando containers...${NC}"
        docker compose down
        echo -e "${GREEN}✓ Containers parados!${NC}"
        ;;

    restart)
        echo -e "${YELLOW}🔄 Reiniciando banco...${NC}"
        docker compose restart postgres
        echo -e "${GREEN}✓ Banco reiniciado!${NC}"
        ;;

    status)
        echo -e "${GREEN}📊 Status dos Containers:${NC}"
        echo ""
        docker compose ps
        echo ""
        echo -e "${GREEN}💾 Estatísticas do Banco:${NC}"
        docker compose exec postgres psql -U tattoo_user -d tattoo_sales_db -c "
            SELECT 
                'Vendas' as tabela, COUNT(*) as registros 
            FROM sales
            UNION ALL
            SELECT 'Produtos', COUNT(*) FROM products
            UNION ALL
            SELECT 'Unidades', COUNT(*) FROM units
            UNION ALL
            SELECT 'Vendedores', COUNT(*) FROM sellers;
        " 2>/dev/null || echo -e "${YELLOW}  Banco ainda não está pronto${NC}"
        ;;

    setup)
        check_env
        echo -e "${GREEN}📦 Gerando dados históricos...${NC}"
        echo -e "${YELLOW}   Isso pode levar ~5-10 minutos${NC}"
        echo ""
        docker compose --profile setup up historical_data
        echo ""
        echo -e "${GREEN}✓ Dados históricos gerados!${NC}"
        echo -e "💡 Execute: ${YELLOW}./manage.sh stats${NC} para ver estatísticas"
        ;;

    generate)
        check_env
        echo -e "${GREEN}🔄 Iniciando gerador contínuo...${NC}"
        docker compose up -d data_generator
        sleep 2
        echo -e "${GREEN}✓ Gerador iniciado!${NC}"
        echo -e "💡 Acompanhe: ${YELLOW}./manage.sh logs-gen${NC}"
        ;;

    stop-gen)
        echo -e "${YELLOW}⏹️  Parando gerador...${NC}"
        docker compose stop data_generator
        echo -e "${GREEN}✓ Gerador parado!${NC}"
        ;;

    restart-gen)
        echo -e "${YELLOW}🔄 Reiniciando gerador...${NC}"
        docker compose restart data_generator
        echo -e "${GREEN}✓ Gerador reiniciado!${NC}"
        ;;

    logs)
        docker compose logs -f
        ;;

    logs-db)
        docker compose logs -f postgres
        ;;

    logs-gen)
        docker compose logs -f data_generator
        ;;

    db)
        echo -e "${GREEN}🗄️  Acessando PostgreSQL...${NC}"
        echo -e "${YELLOW}   Dica: Use \\dt para listar tabelas, \\q para sair${NC}"
        echo ""
        docker compose exec postgres psql -U tattoo_user -d tattoo_sales_db
        ;;

    query)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Uso: ./manage.sh query \"SELECT ...\"${NC}"
            exit 1
        fi
        docker compose exec postgres psql -U tattoo_user -d tattoo_sales_db -c "$2"
        ;;

    stats)
        echo -e "${GREEN}📊 Estatísticas do Banco de Dados${NC}"
        echo ""
        docker compose exec -T postgres psql -U tattoo_user -d tattoo_sales_db << 'EOF'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '📦 REGISTROS POR TABELA'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
SELECT 
    'Vendas' as tabela, 
    COUNT(*) as total,
    COUNT(CASE WHEN canceled THEN 1 END) as canceladas
FROM sales
UNION ALL
SELECT 'Itens de Venda', COUNT(*), 0 FROM sale_items
UNION ALL
SELECT 'Produtos', COUNT(*), 0 FROM products
UNION ALL
SELECT 'Vendedores', COUNT(*), 0 FROM sellers
UNION ALL
SELECT 'Unidades', COUNT(*), 0 FROM units;

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '💰 FATURAMENTO'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
SELECT 
    TO_CHAR(SUM(total_value), 'FM999,999,999.00') as faturamento_total,
    TO_CHAR(AVG(total_value), 'FM999,999.00') as ticket_medio
FROM sales
WHERE NOT canceled;

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '🚚 ENTREGAS'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
SELECT 
    COUNT(CASE WHEN delivered_at IS NOT NULL THEN 1 END) as entregues,
    COUNT(CASE WHEN delivered_at IS NULL AND NOT canceled THEN 1 END) as pendentes,
    ROUND(AVG(expected_delivery_days), 1) as prazo_medio_dias
FROM sales;

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '📈 ÚLTIMAS 24 HORAS'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
SELECT 
    COUNT(*) as vendas,
    TO_CHAR(SUM(total_value), 'FM999,999.00') as faturamento
FROM sales
WHERE sold_at >= NOW() - INTERVAL '24 hours'
  AND NOT canceled;
EOF
        ;;

    backup)
        BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
        echo -e "${GREEN}💾 Criando backup...${NC}"
        docker compose exec postgres pg_dump -U tattoo_user tattoo_sales_db > "$BACKUP_FILE"
        echo -e "${GREEN}✓ Backup criado: ${YELLOW}$BACKUP_FILE${NC}"
        ;;

    restore)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Uso: ./manage.sh restore <arquivo.sql>${NC}"
            exit 1
        fi
        if [ ! -f "$2" ]; then
            echo -e "${RED}❌ Arquivo não encontrado: $2${NC}"
            exit 1
        fi
        echo -e "${YELLOW}⚠️  Restaurando backup...${NC}"
        docker compose exec -T postgres psql -U tattoo_user tattoo_sales_db < "$2"
        echo -e "${GREEN}✓ Backup restaurado!${NC}"
        ;;

    clean)
        echo -e "${RED}⚠️  ATENÇÃO: Isso vai apagar TODOS os dados!${NC}"
        read -p "Tem certeza? Digite 'yes' para confirmar: " -r
        echo
        if [[ $REPLY == "yes" ]]; then
            echo -e "${YELLOW}🧹 Removendo containers e dados...${NC}"
            docker compose down -v
            rm -rf data/ 2>/dev/null || true
            echo -e "${GREEN}✓ Limpeza concluída!${NC}"
        else
            echo -e "${YELLOW}Operação cancelada.${NC}"
        fi
        ;;

    reset)
        echo -e "${RED}⚠️  RESET COMPLETO: Vai apagar tudo e recriar!${NC}"
        read -p "Tem certeza? Digite 'yes' para confirmar: " -r
        echo
        if [[ $REPLY == "yes" ]]; then
            echo -e "${YELLOW}🔄 Executando reset...${NC}"
            docker compose down -v
            rm -rf data/ 2>/dev/null || true
            check_env
            docker compose up -d postgres
            echo ""
            echo -e "${GREEN}✓ Reset concluído!${NC}"
            echo ""
            echo -e "💡 Próximo passo:"
            echo -e "   ${YELLOW}./manage.sh setup${NC} - Gerar dados históricos"
        else
            echo -e "${YELLOW}Operação cancelada.${NC}"
        fi
        ;;

    *)
        usage
        exit 1
        ;;
esac
