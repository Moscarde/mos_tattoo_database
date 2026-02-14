-- ====================================
-- SEED: Products (Produtos Iniciais)
-- ====================================

-- Categoria: Máquinas
INSERT INTO products (name, category, price, active) VALUES
    ('Máquina Rotativa Pro X1', 'Máquinas', 1250.00, TRUE),
    ('Máquina Rotativa Pro X2 Wireless', 'Máquinas', 1850.00, TRUE),
    ('Máquina Bobina Thunder Classic', 'Máquinas', 980.00, TRUE),
    ('Máquina Pen Style Lite', 'Máquinas', 650.00, TRUE),
    ('Máquina Rotativa Elite Gold', 'Máquinas', 2300.00, TRUE),
    ('Máquina Coil Shader Master', 'Máquinas', 1100.00, TRUE);

-- Categoria: Agulhas / Cartuchos
INSERT INTO products (name, category, price, active) VALUES
    ('Cartucho RL 03 - Caixa 20un', 'Agulhas / Cartuchos', 85.00, TRUE),
    ('Cartucho RL 05 - Caixa 20un', 'Agulhas / Cartuchos', 85.00, TRUE),
    ('Cartucho RL 07 - Caixa 20un', 'Agulhas / Cartuchos', 85.00, TRUE),
    ('Cartucho RS 05 - Caixa 20un', 'Agulhas / Cartuchos', 85.00, TRUE),
    ('Cartucho RS 07 - Caixa 20un', 'Agulhas / Cartuchos', 85.00, TRUE),
    ('Cartucho MG 07 - Caixa 20un', 'Agulhas / Cartuchos', 90.00, TRUE),
    ('Cartucho MG 09 - Caixa 20un', 'Agulhas / Cartuchos', 90.00, TRUE),
    ('Agulhas Tradicionais Liner - Pacote 50un', 'Agulhas / Cartuchos', 120.00, TRUE),
    ('Agulhas Tradicionais Shader - Pacote 50un', 'Agulhas / Cartuchos', 120.00, TRUE);

-- Categoria: Fontes
INSERT INTO products (name, category, price, active) VALUES
    ('Fonte Digital Premium 2.0A', 'Fontes', 380.00, TRUE),
    ('Fonte Analógica Classic 1.5A', 'Fontes', 220.00, TRUE),
    ('Fonte Wireless Power Bank', 'Fontes', 780.00, TRUE),
    ('Fonte Dual Output Pro', 'Fontes', 520.00, TRUE);

-- Categoria: Tintas
INSERT INTO products (name, category, price, active) VALUES
    ('Tinta Preta 30ml - Linha Pro', 'Tintas', 45.00, TRUE),
    ('Tinta Preta 120ml - Linha Pro', 'Tintas', 150.00, TRUE),
    ('Kit Tintas Coloridas 12 cores 15ml', 'Tintas', 280.00, TRUE),
    ('Kit Tintas Escala de Cinza 6 tons 30ml', 'Tintas', 240.00, TRUE),
    ('Tinta Branca Especial 30ml', 'Tintas', 60.00, TRUE),
    ('Kit Cores Realistas - 8 cores 30ml', 'Tintas', 320.00, TRUE),
    ('Diluente para Tinta 100ml', 'Tintas', 35.00, TRUE);

-- Categoria: Cabos e grips
INSERT INTO products (name, category, price, active) VALUES
    ('Grip Descartável 25mm - Pacote 100un', 'Cabos e grips', 65.00, TRUE),
    ('Grip Descartável 30mm - Pacote 100un', 'Cabos e grips', 68.00, TRUE),
    ('Grip Descartável 35mm - Pacote 100un', 'Cabos e grips', 72.00, TRUE),
    ('Cabo RCA Premium 2m', 'Cabos e grips', 55.00, TRUE),
    ('Cabo Clip Cord 2m', 'Cabos e grips', 85.00, TRUE),
    ('Grip Alumínio Esterilizável 30mm', 'Cabos e grips', 180.00, TRUE);

-- Categoria: Kits
INSERT INTO products (name, category, price, active) VALUES
    ('Kit Iniciante Completo', 'Kits', 2800.00, TRUE),
    ('Kit Profissional Advanced', 'Kits', 5200.00, TRUE),
    ('Kit Manutenção Máquinas', 'Kits', 320.00, TRUE),
    ('Kit Descartáveis Mix - 200 peças', 'Kits', 180.00, TRUE);

-- Categoria: Higienização
INSERT INTO products (name, category, price, active) VALUES
    ('Barreira Protetora Rolo 200m', 'Higienização', 95.00, TRUE),
    ('Luvas Nitrílicas - Caixa 100un', 'Higienização', 48.00, TRUE),
    ('Álcool Gel 70% - 1L', 'Higienização', 22.00, TRUE),
    ('Lençol Descartável - Pacote 50un', 'Higienização', 55.00, TRUE),
    ('Saco Esterilização Autoclace - 100un', 'Higienização', 75.00, TRUE),
    ('Spray Desinfetante Premium 500ml', 'Higienização', 38.00, TRUE),
    ('Campo Cirúrgico Descartável - 50un', 'Higienização', 68.00, TRUE),
    ('Toalha Bactericida - Pote 100un', 'Higienização', 42.00, TRUE);

-- ====================================
-- Estatísticas do Catálogo
-- ====================================
-- Total: 50 produtos
-- Máquinas: 6
-- Agulhas / Cartuchos: 9
-- Fontes: 4
-- Tintas: 7
-- Cabos e grips: 6
-- Kits: 4
-- Higienização: 8
