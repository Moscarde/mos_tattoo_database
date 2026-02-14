#!/usr/bin/env python3
"""
Script para gerar vendas em tempo real.
Insere 1 nova venda a cada 60 segundos com timestamp atual.
Roda continuamente em loop.
"""

import os
import random
import signal
import sys
import time
from datetime import datetime, timedelta
from typing import Dict, List, Tuple

import psycopg2
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

# Configurações
DATABASE_URL = os.getenv("DATABASE_URL")
INTERVAL_SECONDS = 60  # 1 venda por minuto

# Pesos para distribuição de vendas por unidade (5 unidades)
UNIT_WEIGHTS = {
    1: 0.30,  # SP Centro - 30%
    2: 0.25,  # RJ Copacabana - 25%
    3: 0.20,  # BH Savassi - 20%
    4: 0.15,  # CT Batel - 15%
    5: 0.10,  # POA Moinhos - 10%
}

# Taxa de cancelamento (3% a 8%)
CANCEL_RATE_RANGE = (0.03, 0.08)

# Tempo de entrega esperado (1 a 15 dias)
EXPECTED_DELIVERY_RANGE = (1, 15)

# Variação na entrega real: -2 a +5 dias da expectativa
DELIVERY_VARIATION_RANGE = (-2, 5)

# Itens por venda (1 a 5)
ITEMS_PER_SALE_RANGE = (1, 5)

# Flag para parada graceful
running = True


def signal_handler(sig, frame):
    """Handler para sinais de interrupção."""
    global running
    print("\n\n🛑 Recebido sinal de parada. Finalizando...")
    running = False


class RealtimeGenerator:
    def __init__(self, database_url: str):
        self.database_url = database_url
        self.conn = None
        self.cursor = None
        self.units = []
        self.sellers_by_unit = {}
        self.products = []
        self.sales_count = 0
        self.start_time = datetime.now()

    def connect(self):
        """Conecta ao banco de dados com retry."""
        max_retries = 5
        retry_delay = 5

        for attempt in range(max_retries):
            try:
                self.conn = psycopg2.connect(self.database_url)
                self.cursor = self.conn.cursor()
                print("✓ Conectado ao banco de dados")
                return True
            except Exception as e:
                if attempt < max_retries - 1:
                    print(f"⚠ Tentativa {attempt + 1}/{max_retries} falhou: {e}")
                    print(f"  Aguardando {retry_delay}s antes de tentar novamente...")
                    time.sleep(retry_delay)
                else:
                    print(f"✗ Erro ao conectar após {max_retries} tentativas: {e}")
                    return False

    def close(self):
        """Fecha a conexão com o banco."""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()

    def load_data(self):
        """Carrega unidades, vendedores e produtos do banco."""
        try:
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

            return True
        except Exception as e:
            print(f"✗ Erro ao carregar dados: {e}")
            return False

    def select_unit(self) -> int:
        """Seleciona uma unidade baseada nos pesos configurados."""
        units = list(UNIT_WEIGHTS.keys())
        weights = list(UNIT_WEIGHTS.values())
        return random.choices(units, weights=weights, k=1)[0]

    def generate_sale_data(self) -> Tuple[Dict, List[Dict]]:
        """Gera dados de uma venda completa com timestamp atual."""
        # Selecionar unidade e vendedor
        unit_id = self.select_unit()
        seller_id = random.choice(self.sellers_by_unit[unit_id])

        # Determinar se está cancelada
        canceled = random.random() < random.uniform(*CANCEL_RATE_RANGE)

        # Tempo de entrega esperado
        expected_delivery_days = random.randint(*EXPECTED_DELIVERY_RANGE)
        
        # Vendas em tempo real ainda não foram entregues
        # delivered_at será sempre None pois a venda acabou de acontecer
        sold_at = datetime.now()
        delivered_at = None

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
            "sold_at": sold_at,
            "unit_id": unit_id,
            "seller_id": seller_id,
            "total_value": round(total_value, 2),
            "expected_delivery_days": expected_delivery_days,
            "delivered_at": delivered_at,
            "canceled": canceled,
        }

        return sale, items

    def insert_sale(self, sale: Dict, items: List[Dict]) -> bool:
        """Insere uma venda e seus itens no banco."""
        try:
            # Inserir venda
            sales_insert = """
                INSERT INTO sales (sold_at, unit_id, seller_id, total_value, expected_delivery_days, delivered_at, canceled)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """

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
            sale_id = self.cursor.fetchone()[0]

            # Inserir itens
            items_insert = """
                INSERT INTO sale_items (sale_id, product_id, quantity, unit_price)
                VALUES (%s, %s, %s, %s)
            """

            for item in items:
                self.cursor.execute(
                    items_insert,
                    (sale_id, item["product_id"], item["quantity"], item["unit_price"]),
                )

            self.conn.commit()
            self.sales_count += 1

            return True

        except Exception as e:
            self.conn.rollback()
            print(f"\n✗ Erro ao inserir venda: {e}")
            return False

    def get_unit_name(self, unit_id: int) -> str:
        """Retorna o nome da unidade."""
        try:
            self.cursor.execute("SELECT code FROM units WHERE id = %s", (unit_id,))
            result = self.cursor.fetchone()
            return result[0] if result else f"Unit-{unit_id}"
        except:
            return f"Unit-{unit_id}"

    def print_sale_info(self, sale: Dict, items: List[Dict]):
        """Imprime informações sobre a venda gerada."""
        unit_name = self.get_unit_name(sale["unit_id"])
        status = "❌ CANCELADA" if sale["canceled"] else "✓"

        print(f"\n{'=' * 70}")
        print(f"🛒 Nova Venda #{self.sales_count}")
        print(f"{'=' * 70}")
        print(f"  Data/Hora: {sale['sold_at'].strftime('%d/%m/%Y %H:%M:%S')}")
        print(f"  Unidade: {unit_name}")
        print(f"  Vendedor ID: {sale['seller_id']}")
        print(f"  Itens: {len(items)}")
        print(f"  Valor Total: R$ {sale['total_value']:.2f}")
        if not sale["canceled"]:
            print(f"  Prazo de Entrega: {sale['expected_delivery_days']} dias")
            expected_date = sale['sold_at'] + timedelta(days=sale['expected_delivery_days'])
            print(f"  Entrega Prevista: {expected_date.strftime('%d/%m/%Y')}")
        print(f"  Status: {status}")
        print(f"{'=' * 70}")

    def run(self):
        """Loop principal de geração de vendas."""
        print("\n" + "=" * 70)
        print("🚀 GERADOR DE VENDAS EM TEMPO REAL")
        print("=" * 70)
        print(f"Intervalo: {INTERVAL_SECONDS}s por venda")
        print(f"Iniciado em: {self.start_time.strftime('%d/%m/%Y %H:%M:%S')}")
        print("Pressione Ctrl+C para parar")
        print("=" * 70)

        last_stats_time = datetime.now()

        while running:
            try:
                # Gerar e inserir venda
                sale, items = self.generate_sale_data()
                
                if self.insert_sale(sale, items):
                    self.print_sale_info(sale, items)

                    # Mostrar estatísticas a cada 10 vendas
                    if self.sales_count % 10 == 0:
                        self.print_statistics()

                # Aguardar intervalo
                if running:  # Verificar se ainda está rodando antes de dormir
                    print(f"\n⏳ Aguardando {INTERVAL_SECONDS}s até a próxima venda...")
                    time.sleep(INTERVAL_SECONDS)

            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"\n⚠ Erro no loop: {e}")
                print("Tentando reconectar em 10s...")
                time.sleep(10)
                if not self.connect() or not self.load_data():
                    break

        # Estatísticas finais
        print("\n" + "=" * 70)
        print("🏁 SESSÃO FINALIZADA")
        print("=" * 70)
        self.print_statistics()
        print("=" * 70)


def main():
    """Função principal."""
    # Registrar handlers de sinal
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    if not DATABASE_URL:
        print("✗ Erro: DATABASE_URL não configurada")
        print("Configure a variável de ambiente DATABASE_URL")
        sys.exit(1)

    generator = RealtimeGenerator(DATABASE_URL)

    try:
        if not generator.connect():
            sys.exit(1)

        if not generator.load_data():
            sys.exit(1)

        generator.run()

    except Exception as e:
        print(f"\n✗ Erro fatal: {e}")
        sys.exit(1)
    finally:
        generator.close()
        print("\n✓ Conexão fechada. Até logo!")


if __name__ == "__main__":
    main()
