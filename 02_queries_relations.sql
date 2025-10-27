/* INNER JOIN: продукты с категориями и их основными поставщиками */
SELECT
    p.name AS product_name,
    p.price,
    c.name AS category_name,
    s.company_name AS supplier_name
FROM products p
INNER JOIN categories c ON p.category_id = c.id
INNER JOIN suppliers s ON c.main_supplier_id = s.id;

/* LEFT JOIN: все категории, даже без продуктов */
SELECT
    c.name AS category_name,
    COUNT(p.id) AS product_count
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
GROUP BY c.id, c.name
ORDER BY product_count DESC;

/* LEFT JOIN: все поставщики и их товары (если есть) */
SELECT
    s.company_name,
    p.name AS product_name,
    ps.purchase_price
FROM suppliers s
LEFT JOIN product_suppliers ps ON s.id = ps.supplier_id
LEFT JOIN products p ON ps.product_id = p.id;

/* Многотабличный запрос: полная карточка продукта */
SELECT
    p.name AS product_name,
    p.price,
    c.name AS category_name,
    pd.weight_kg,
    pd.manufacturer,
    GROUP_CONCAT(t.name) AS tags,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM products p
INNER JOIN categories c ON p.category_id = c.id
LEFT JOIN product_details pd ON p.id = pd.product_id
LEFT JOIN product_tags pt ON p.id = pt.product_id
LEFT JOIN tags t ON pt.tag_id = t.id
LEFT JOIN reviews r ON p.id = r.product_id
GROUP BY p.id, p.name, p.price, c.name, pd.weight_kg, pd.manufacturer;

/* Работа с M–M: продукты и их теги (плоским списком) */
SELECT
    p.name AS product_name,
    t.name AS tag_name,
    t.description AS tag_description
FROM products p
INNER JOIN product_tags pt ON p.id = pt.product_id
INNER JOIN tags t ON pt.tag_id = t.id
ORDER BY p.name, t.name;

/* Теги и количество продуктов */
SELECT
    t.name AS tag_name,
    COUNT(pt.product_id) AS product_count
FROM tags t
LEFT JOIN product_tags pt ON t.id = pt.tag_id
GROUP BY t.id, t.name
ORDER BY product_count DESC;

/* Поставщики и ассортимент */
SELECT
    s.company_name,
    COUNT(ps.product_id) AS products_supplied,
    GROUP_CONCAT(p.name) AS product_list
FROM suppliers s
LEFT JOIN product_suppliers ps ON s.id = ps.supplier_id
LEFT JOIN products p ON ps.product_id = p.id
GROUP BY s.id, s.company_name;

/* Аналитика: рейтинг продуктов по отзывам */
SELECT
    p.name AS product_name,
    COUNT(r.id) AS review_count,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    c.name AS category_name
FROM products p
LEFT JOIN reviews r ON p.id = r.product_id
INNER JOIN categories c ON p.category_id = c.id
GROUP BY p.id, p.name, c.name
HAVING review_count > 0
ORDER BY avg_rating DESC, review_count DESC;

/* Аналитика: маржинальность продуктов по минимальной закупке */
SELECT
    p.name AS product_name,
    p.price AS selling_price,
    MIN(ps.purchase_price) AS min_purchase_price,
    ROUND((p.price - MIN(ps.purchase_price)) / p.price * 100, 2) AS margin_percent
FROM products p
INNER JOIN product_suppliers ps ON p.id = ps.product_id
GROUP BY p.id, p.name, p.price
ORDER BY margin_percent DESC;

/* Аналитика: статистика по категориям */
SELECT
    c.name AS category_name,
    COUNT(p.id) AS product_count,
    COUNT(DISTINCT ps.supplier_id) AS supplier_count,
    ROUND(AVG(p.price), 2) AS avg_price,
    SUM(p.stock_quantity) AS total_stock
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
LEFT JOIN product_suppliers ps ON p.id = ps.product_id
GROUP BY c.id, c.name
ORDER BY product_count DESC;
