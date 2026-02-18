#!/usr/bin/env python3
"""
Script para gerar dados históricos de vendas.
Gera vendas desde hoje - 365 dias até agora.
Média de 4 vendas por dia (~1.460 vendas/ano).
Faturamento estimado entre 8M e 12M por ano.
"""

import os
import random
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Tuple

import psycopg2
from dotenv import load_dotenv
from psycopg2.extras import execute_batch

# Carregar variáveis de ambiente
load_dotenv()

# Configurações
DATABASE_URL = os.getenv("DATABASE_URL")
DAYS_BACK = 365
SALES_PER_DAY = 4  # Reduzido para manter faturamento entre 1M e 10M/ano

# Pesos base para distribuição de vendas por unidade (5 unidades)
# Estes valores serão variados mensalmente para criar padrões mais realistas
BASE_UNIT_WEIGHTS = {
    1: 0.30,  # SP Centro - 30%
    2: 0.25,  # RJ Copacabana - 25%
    3: 0.20,  # BH Savassi - 20%
    4: 0.15,  # CT Batel - 15%
    5: 0.10,  # POA Moinhos - 10%
}

# Variação mensal permitida nos pesos (±30%)
MONTHLY_WEIGHT_VARIATION = 0.30

# Taxa de cancelamento por unidade (3% a 8%)
CANCEL_RATE_RANGE = (0.03, 0.08)

# Tempo de entrega esperado (1 a 15 dias)
EXPECTED_DELIVERY_RANGE = (1, 15)

# Variação na entrega real: -2 a +5 dias da expectativa
# (pode entregar 2 dias antes ou até 5 dias depois do esperado)
DELIVERY_VARIATION_RANGE = (-2, 5)

# Itens por venda (1 a 5)
ITEMS_PER_SALE_RANGE = (1, 5)


class DataGenerator:
    def __init__(self, database_url: str):
        self.database_url = database_url
        self.conn = None
        self.cursor = None
        self.units = []
        self.sellers_by_unit = {}
        self.products = []

    def connect(self):
        """Conecta ao banco de dados."""
        try:
            self.conn = psycopg2.connect(self.database_url)
            self.cursor = self.conn.cursor()
            print("✓ Conectado ao banco de dados")
        except Exception as e:
            print(f"✗ Erro ao conectar: {e}")
            sys.exit(1)

    def close(self):
        """Fecha a conexão com o banco."""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()

    def load_data(self):
        """Carrega unidades, vendedores e produtos do banco."""
        # Carregar unidades
        self.cursor.execute("SELECT id FROM units WHERE active = TRUE")
        self.units = [row[0] for row in self.cursor.fetchall()]
        print(f"✓ Carregadas {len(self.units)} unidades")

        # Carregar vendedores por unidade
        self.cursor.execute(
            """
            SELECT id, unit_id FROM sellers WHERE active = TRUE
        """
        )
        for seller_id, unit_id in self.cursor.fetchall():
            if unit_id not in self.sellers_by_unit:
                self.sellers_by_unit[unit_id] = []
            self.sellers_by_unit[unit_id].append(seller_id)
        print(f"✓ Carregados vendedores para {len(self.sellers_by_unit)} unidades")

        # Carregar produtos
        self.cursor.execute(
            """
            SELECT id, price FROM products WHERE active = TRUE
        """
        )
        self.products = [(row[0], float(row[1])) for row in self.cursor.fetchall()]
        print(f"✓ Carregados {len(self.products)} produtos")

    def generate_sale_timestamp(
        self, start_date: datetime, end_date: datetime
    ) -> datetime:
        """Gera um timestamp aleatório entre start_date e end_date."""
        time_delta = end_date - start_date
        random_seconds = random.randint(0, int(time_delta.total_seconds()))
        return start_date + timedelta(seconds=random_seconds)

    def get_monthly_weights(self, timestamp: datetime) -> Dict[int, float]:
        """
        Gera pesos variáveis por unidade baseados no mês.
        Isso cria padrões mais realistas onde uma loja pode performar
        bem em um mês e mal em outro.
        """
        # Usar ano e mês como seed para consistência no mesmo mês
        month_seed = timestamp.year * 12 + timestamp.month
        rng = random.Random(month_seed)

        # Aplicar variação aleatória aos pesos base
        monthly_weights = {}
        for unit_id, base_weight in BASE_UNIT_WEIGHTS.items():
            # Variação entre -30% e +30% do peso base
            variation = rng.uniform(-MONTHLY_WEIGHT_VARIATION, MONTHLY_WEIGHT_VARIATION)
            varied_weight = base_weight * (1 + variation)
            # Garantir que não seja negativo
            monthly_weights[unit_id] = max(0.05, varied_weight)

        # Normalizar para que a soma seja 1.0
        total_weight = sum(monthly_weights.values())
        for unit_id in monthly_weights:
            monthly_weights[unit_id] /= total_weight

        return monthly_weights

    def select_unit(self, timestamp: datetime) -> int:
        """Seleciona uma unidade baseada nos pesos variáveis por mês."""
        monthly_weights = self.get_monthly_weights(timestamp)
        units = list(monthly_weights.keys())
        weights = list(monthly_weights.values())
        return random.choices(units, weights=weights, k=1)[0]

    def generate_sale_data(self, timestamp: datetime) -> Tuple[Dict, List[Dict]]:
        """Gera dados de uma venda completa."""
        # Selecionar unidade e vendedor (usando timestamp para variação mensal)
        unit_id = self.select_unit(timestamp)
        seller_id = random.choice(self.sellers_by_unit[unit_id])

        # Determinar se está cancelada
        canceled = random.random() < random.uniform(*CANCEL_RATE_RANGE)

        # Tempo de entrega esperado
        expected_delivery_days = random.randint(*EXPECTED_DELIVERY_RANGE)

        # Calcular data de entrega real (apenas se já deveria ter sido entregue)
        # Vendas canceladas não têm entrega
        delivered_at = None
        if not canceled:
            delivery_variation = random.randint(*DELIVERY_VARIATION_RANGE)
            actual_delivery_days = max(1, expected_delivery_days + delivery_variation)
            potential_delivery_date = timestamp + timedelta(days=actual_delivery_days)

            # Só define delivered_at se a data já passou (não pode ser no futuro)
            if potential_delivery_date <= datetime.now():
                delivered_at = potential_delivery_date

        # Gerar itens da venda
        num_items = random.randint(*ITEMS_PER_SALE_RANGE)
        selected_products = random.sample(
            self.products, min(num_items, len(self.products))
        )

        items = []
        total_value = 0.0

        for product_id, base_price in selected_products:
            quantity = random.randint(1, 10)
            # Variação de preço de -10% a +5%
            price_variation = random.uniform(0.90, 1.05)
            unit_price = round(base_price * price_variation, 2)
            item_total = unit_price * quantity
            total_value += item_total

            items.append(
                {
                    "product_id": product_id,
                    "quantity": quantity,
                    "unit_price": unit_price,
                }
            )

        sale = {
            "sold_at": timestamp,
            "unit_id": unit_id,
            "seller_id": seller_id,
            "total_value": round(total_value, 2),
            "expected_delivery_days": expected_delivery_days,
            "delivered_at": delivered_at,
            "canceled": canceled,
        }

        return sale, items

    def insert_sales_batch(self, sales_data: List[Tuple[Dict, List[Dict]]]):
        """Insere um lote de vendas e seus itens."""
        try:
            # Inserir vendas
            sales_insert = """
                INSERT INTO sales (sold_at, unit_id, seller_id, total_value, expected_delivery_days, delivered_at, canceled)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """

            sale_ids = []
            for sale, _ in sales_data:
                self.cursor.execute(
                    sales_insert,
                    (
                        sale["sold_at"],
                        sale["unit_id"],
                        sale["seller_id"],
                        sale["total_value"],
                        sale["expected_delivery_days"],
                        sale["delivered_at"],
                        sale["canceled"],
                    ),
                )
                sale_ids.append(self.cursor.fetchone()[0])

            # Inserir itens
            items_insert = """
                INSERT INTO sale_items (sale_id, product_id, quantity, unit_price)
                VALUES (%s, %s, %s, %s)
            """

            items_batch = []
            for sale_id, (_, items) in zip(sale_ids, sales_data):
                for item in items:
                    items_batch.append(
                        (
                            sale_id,
                            item["product_id"],
                            item["quantity"],
                            item["unit_price"],
                        )
                    )

            execute_batch(self.cursor, items_insert, items_batch, page_size=1000)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"✗ Erro ao inserir vendas: {e}")
            raise

    def generate_historical_data(self):
        """Gera todos os dados históricos."""
        print("\n" + "=" * 60)
        print("GERAÇÃO DE DADOS HISTÓRICOS")
        print("=" * 60)

        end_date = datetime.now()
        start_date = end_date - timedelta(days=DAYS_BACK)

        print(
            f"\nPeríodo: {start_date.strftime('%d/%m/%Y %H:%M')} até {end_date.strftime('%d/%m/%Y %H:%M')}"
        )
        print(f"Vendas por dia: ~{SALES_PER_DAY}")
        print(f"Total estimado: ~{DAYS_BACK * SALES_PER_DAY:,} vendas\n")

        # Gerar timestamps para todas as vendas
        print("Gerando timestamps...")
        timestamps = sorted(
            [
                self.generate_sale_timestamp(start_date, end_date)
                for _ in range(DAYS_BACK * SALES_PER_DAY)
            ]
        )

        # Gerar vendas em lotes
        batch_size = 1000
        total_batches = (len(timestamps) + batch_size - 1) // batch_size

        print(f"Inserindo vendas em {total_batches} lotes de {batch_size}...\n")

        for batch_num in range(total_batches):
            start_idx = batch_num * batch_size
            end_idx = min((batch_num + 1) * batch_size, len(timestamps))
            batch_timestamps = timestamps[start_idx:end_idx]

            # Gerar dados das vendas
            sales_data = []
            for ts in batch_timestamps:
                sale, items = self.generate_sale_data(ts)
                sales_data.append((sale, items))

            # Inserir no banco
            self.insert_sales_batch(sales_data)

            # Progresso
            progress = ((batch_num + 1) / total_batches) * 100
            print(
                f"Progresso: {progress:.1f}% ({end_idx:,}/{len(timestamps):,} vendas)"
            )

        print("\n" + "=" * 60)
        print("✓ GERAÇÃO CONCLUÍDA COM SUCESSO!")
        print("=" * 60)

        # Estatísticas finais
        self.print_statistics()

    def print_statistics(self):
        """Imprime estatísticas dos dados gerados."""
        print("\nESTATÍSTICAS:")
        print("-" * 60)

        # Total de vendas
        self.cursor.execute("SELECT COUNT(*) FROM sales")
        total_sales = self.cursor.fetchone()[0]
        print(f"Total de vendas: {total_sales:,}")

        # Vendas canceladas
        self.cursor.execute("SELECT COUNT(*) FROM sales WHERE canceled = TRUE")
        canceled_sales = self.cursor.fetchone()[0]
        cancel_rate = (canceled_sales / total_sales * 100) if total_sales > 0 else 0
        print(f"Vendas canceladas: {canceled_sales:,} ({cancel_rate:.2f}%)")

        # Valor total
        self.cursor.execute("SELECT SUM(total_value) FROM sales WHERE canceled = FALSE")
        total_revenue = self.cursor.fetchone()[0] or 0
        print(f"Faturamento total: R$ {total_revenue:,.2f}")

        # Ticket médio
        if total_sales > canceled_sales:
            avg_ticket = total_revenue / (total_sales - canceled_sales)
            print(f"Ticket médio: R$ {avg_ticket:.2f}")

        # Tempo médio de entrega esperado
        self.cursor.execute("SELECT AVG(expected_delivery_days) FROM sales")
        avg_expected = self.cursor.fetchone()[0] or 0
        print(f"Tempo médio esperado: {avg_expected:.1f} dias")

        # Tempo médio de entrega real
        self.cursor.execute(
            """
            SELECT AVG(EXTRACT(DAY FROM (delivered_at - sold_at)))
            FROM sales 
            WHERE delivered_at IS NOT NULL
        """
        )
        avg_actual = self.cursor.fetchone()[0] or 0
        print(f"Tempo médio real: {avg_actual:.1f} dias")

        # Entregas no prazo
        self.cursor.execute(
            """
            SELECT COUNT(*)
            FROM sales
            WHERE delivered_at IS NOT NULL
              AND EXTRACT(DAY FROM (delivered_at - sold_at)) <= expected_delivery_days
        """
        )
        on_time = self.cursor.fetchone()[0] or 0
        self.cursor.execute("SELECT COUNT(*) FROM sales WHERE delivered_at IS NOT NULL")
        total_delivered = self.cursor.fetchone()[0] or 0
        on_time_rate = (on_time / total_delivered * 100) if total_delivered > 0 else 0
        print(
            f"Entregas no prazo: {on_time:,} de {total_delivered:,} ({on_time_rate:.1f}%)"
        )

        # Total de itens vendidos
        self.cursor.execute("SELECT SUM(quantity) FROM sale_items")
        total_items = self.cursor.fetchone()[0] or 0
        print(f"Total de itens vendidos: {total_items:,}")

        print("-" * 60)


def main():
    """Função principal."""
    if not DATABASE_URL:
        print("✗ Erro: DATABASE_URL não configurada")
        print("Configure a variável de ambiente DATABASE_URL ou crie um arquivo .env")
        sys.exit(1)

    print("\n" + "=" * 60)
    print("GERADOR DE DADOS HISTÓRICOS - TATTOO SALES")
    print("=" * 60)

    generator = DataGenerator(DATABASE_URL)

    try:
        generator.connect()
        generator.load_data()
        generator.generate_historical_data()
    except KeyboardInterrupt:
        print("\n\n✗ Processo interrompido pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ Erro: {e}")
        sys.exit(1)
    finally:
        generator.close()


if __name__ == "__main__":
    main()
