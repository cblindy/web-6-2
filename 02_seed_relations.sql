PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- Поставщики
INSERT INTO suppliers (company_name, contact_name, phone, email) VALUES
('TechSupply Inc.', 'Алексей Иванов', '+7-999-123-4567', 'alex@techsupply.ru'),
('FashionStyle Ltd.', 'Мария Петрова', '+7-999-765-4321', 'maria@fashionstyle.ru'),
('BookWorld Corp.', 'Дмитрий Сидоров', '+7-999-555-8888', 'dmitry@bookworld.ru');

-- Основные поставщики для категорий
UPDATE categories SET main_supplier_id = 1 WHERE name = 'Электроника';
UPDATE categories SET main_supplier_id = 2 WHERE name = 'Одежда';
UPDATE categories SET main_supplier_id = 3 WHERE name = 'Книги';

-- Детали продуктов (1–1)
INSERT INTO product_details (product_id, weight_kg, dimensions, manufacturer, warranty_months) VALUES
(1, 0.172, '146.7×71.5×7.8 mm', 'Apple Inc.', 12),
(2, 0.168, '146.3×70.9×7.6 mm', 'Samsung Electronics', 24),
(3, 0.150, 'M', 'CottonWorks', NULL),
(4, 0.400, '32×32', 'DenimMaster', NULL);

-- Продукты ↔ поставщики (M–M)
INSERT INTO product_suppliers (product_id, supplier_id, purchase_price, delivery_days) VALUES
(1, 1, 650.00, 7),
(2, 1, 600.00, 5),
(3, 2, 12.00, 3),
(4, 2, 30.00, 4),
(5, 3, 15.00, 2);

-- Теги и привязки (M–M)
INSERT INTO tags (name, description) VALUES
('новинка', 'Новые поступления'),
('хит', 'Популярные товары'),
('акция', 'Товары со скидкой'),
('премиум', 'Премиальные товары'),
('эко', 'Экологичные товары');

INSERT INTO product_tags (product_id, tag_id) VALUES
(1, 1), (1, 4),
(2, 1), (2, 2),
(3, 3), (3, 5),
(5, 2);

-- Отзывы (1–M)
INSERT INTO reviews (product_id, customer_id, rating, comment) VALUES
(1, 1, 5, 'Отличный телефон! Батарея держит долго.'),
(1, 2, 4, 'Хороший аппарат, но дорогой.'),
(2, 3, 5, 'Лучший Android телефон на рынке!'),
(3, 1, 3, 'Нормальная футболка за свои деньги.'),
(3, 2, 4, 'Удобная и качественная.');

COMMIT;
