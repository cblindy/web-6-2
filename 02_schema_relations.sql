PRAGMA foreign_keys = ON;

/* 1) Новая сущность поставщиков (отдельная таблица) */
CREATE TABLE IF NOT EXISTS suppliers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    company_name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(150),
    address TEXT
);

/* 2) Добавляем в categories внешний ключ на основного поставщика.
   Т.к. SQLite не умеет ADD FOREIGN KEY, делаем корректную миграцию через переименование. */
BEGIN TRANSACTION;

-- Если столбца main_supplier_id ещё нет — пересоздаём таблицу корректно
CREATE TABLE IF NOT EXISTS categories_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    main_supplier_id INTEGER,
    FOREIGN KEY (main_supplier_id) REFERENCES suppliers(id)
);

-- Переносим данные из старой categories (если существует)
INSERT INTO categories_new (id, name, description, created_at)
SELECT id, name, description, COALESCE(created_at, CURRENT_TIMESTAMP)
FROM categories;

-- Переименовываем таблицы
DROP TABLE categories;
ALTER TABLE categories_new RENAME TO categories;

COMMIT;

/* 3) Отношение 1–1: расширенная информация о продукте */
CREATE TABLE IF NOT EXISTS product_details (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER UNIQUE NOT NULL,
    weight_kg DECIMAL(8,3),
    dimensions VARCHAR(50),
    manufacturer VARCHAR(100),
    warranty_months INTEGER,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

/* 4) Отношение M–M: продукты ↔ поставщики (с атрибутами связи) */
CREATE TABLE IF NOT EXISTS product_suppliers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    supplier_id INTEGER NOT NULL,
    purchase_price DECIMAL(10,2),
    delivery_days INTEGER,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE,
    UNIQUE(product_id, supplier_id)
);

/* 5) Отношение M–M: продукты ↔ теги */
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS product_tags (
    product_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (product_id, tag_id),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

/* 6) Отношение 1–M: отзывы к продуктам */
CREATE TABLE IF NOT EXISTS reviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
