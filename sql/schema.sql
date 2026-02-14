-- ====================================
-- SCHEMA: Tattoo Sales Database
-- ====================================

-- Extensões
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ====================================
-- Tabela: units (Unidades de Venda)
-- ====================================
CREATE TABLE units (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_units_active ON units(active);
CREATE INDEX idx_units_code ON units(code);

-- ====================================
-- Tabela: sellers (Vendedores)
-- ====================================
CREATE TABLE sellers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit_id INTEGER NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE CASCADE
);

CREATE INDEX idx_sellers_unit ON sellers(unit_id);
CREATE INDEX idx_sellers_active ON sellers(active);

-- ====================================
-- Tabela: products (Produtos)
-- ====================================
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_active ON products(active);

-- ====================================
-- Tabela: sales (Vendas)
-- ====================================
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    sold_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unit_id INTEGER NOT NULL,
    seller_id INTEGER NOT NULL,
    total_value DECIMAL(10, 2) NOT NULL CHECK (total_value >= 0),
    expected_delivery_days INTEGER NOT NULL CHECK (expected_delivery_days >= 0),
    delivered_at TIMESTAMP,
    canceled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE CASCADE,
    FOREIGN KEY (seller_id) REFERENCES sellers(id) ON DELETE CASCADE
);

CREATE INDEX idx_sales_sold_at ON sales(sold_at);
CREATE INDEX idx_sales_unit ON sales(unit_id);
CREATE INDEX idx_sales_seller ON sales(seller_id);
CREATE INDEX idx_sales_canceled ON sales(canceled);
CREATE INDEX idx_sales_sold_at_canceled ON sales(sold_at, canceled);
CREATE INDEX idx_sales_delivered_at ON sales(delivered_at);

-- ====================================
-- Tabela: sale_items (Itens da Venda)
-- ====================================
CREATE TABLE sale_items (
    id SERIAL PRIMARY KEY,
    sale_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);

-- ====================================
-- Views para facilitar consultas
-- ====================================

-- View: Vendas com informações completas
CREATE VIEW v_sales_complete AS
SELECT 
    s.id,
    s.sold_at,
    s.delivered_at,
    u.name AS unit_name,
    u.code AS unit_code,
    sel.name AS seller_name,
    s.total_value,
    s.expected_delivery_days,
    CASE 
        WHEN s.delivered_at IS NULL THEN NULL
        ELSE EXTRACT(DAY FROM (s.delivered_at - s.sold_at))
    END AS actual_delivery_days,
    CASE 
        WHEN s.delivered_at IS NULL THEN NULL
        WHEN EXTRACT(DAY FROM (s.delivered_at - s.sold_at)) <= s.expected_delivery_days THEN TRUE
        ELSE FALSE
    END AS delivered_on_time,
    s.canceled
FROM sales s
JOIN units u ON s.unit_id = u.id
JOIN sellers sel ON s.seller_id = sel.id;

-- View: Itens de venda com detalhes de produto
CREATE VIEW v_sale_items_detail AS
SELECT 
    si.id,
    si.sale_id,
    s.sold_at,
    p.name AS product_name,
    p.category AS product_category,
    si.quantity,
    si.unit_price,
    (si.quantity * si.unit_price) AS item_total
FROM sale_items si
JOIN sales s ON si.sale_id = s.id
JOIN products p ON si.product_id = p.id;

-- ====================================
-- Seed inicial de unidades
-- ====================================

INSERT INTO units (name, code, active) VALUES
    ('Unidade São Paulo - Centro', 'SP-01', TRUE),
    ('Unidade Rio de Janeiro - Copacabana', 'RJ-01', TRUE),
    ('Unidade Belo Horizonte - Savassi', 'BH-01', TRUE),
    ('Unidade Curitiba - Batel', 'CT-01', TRUE),
    ('Unidade Porto Alegre - Moinhos', 'POA-01', TRUE);



-- ====================================
-- Seed inicial de vendedores
-- ====================================
INSERT INTO sellers (name, unit_id, active) VALUES
    -- SP Centro (3 vendedores)
    ('Carlos Silva', 1, TRUE),
    ('Maria Santos', 1, TRUE),
    ('João Oliveira', 1, TRUE),
    -- RJ Copacabana (3 vendedores)
    ('Ana Costa', 2, TRUE),
    ('Pedro Lima', 2, TRUE),
    ('Julia Ferreira', 2, TRUE),
    -- BH Savassi (2 vendedores)
    ('Lucas Almeida', 3, TRUE),
    ('Fernanda Souza', 3, TRUE),
    -- CT Batel (2 vendedores)
    ('Bruno Dias', 4, TRUE),
    ('Patricia Gomes', 4, TRUE),
    -- POA Moinhos (2 vendedores)
    ('Rafael Martins', 5, TRUE),
    ('Camila Rocha', 5, TRUE);

-- ====================================
-- Comentários para documentação
-- ====================================
COMMENT ON TABLE units IS 'Unidades de venda da fábrica de insumos para tatuagem';
COMMENT ON TABLE sellers IS 'Vendedores associados às unidades';
COMMENT ON TABLE products IS 'Catálogo de produtos disponíveis';
COMMENT ON TABLE sales IS 'Registro de vendas realizadas';
COMMENT ON TABLE sale_items IS 'Itens detalhados de cada venda';

COMMENT ON COLUMN sales.expected_delivery_days IS 'Expectativa de dias para entrega (1-15)';
COMMENT ON COLUMN sales.delivered_at IS 'Data/hora real da entrega (NULL se ainda não entregue)';
COMMENT ON COLUMN sales.canceled IS 'Indica se a venda foi cancelada';
