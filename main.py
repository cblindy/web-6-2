import sqlite3
from contextlib import contextmanager

DB_NAME = "shop.db"


@contextmanager
def txn(conn):
	try:
		conn.execute("BEGIN")
		yield
		conn.commit()
	except sqlite3.Error:
		conn.rollback()
		raise


class AdvancedDatabaseManager:
	def __init__(self, db_name=DB_NAME):
		self.db_name = db_name
		self.connection = None

	def connect(self):
		self.connection = sqlite3.connect(self.db_name)
		self.connection.execute("PRAGMA foreign_keys = ON")
		self.connection.row_factory = sqlite3.Row

	def close(self):
		if self.connection:
			self.connection.close()

	def get_products_with_details(self):
		q = """
        SELECT
            p.id, p.name, p.price, p.stock_quantity,
            c.name AS category_name,
            pd.weight_kg, pd.manufacturer, pd.warranty_months,
            GROUP_CONCAT(DISTINCT t.name) AS tags,
            ROUND(AVG(r.rating), 2) AS avg_rating,
            COUNT(r.id) AS review_count
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN product_details pd ON p.id = pd.product_id
        LEFT JOIN product_tags pt ON p.id = pt.product_id
        LEFT JOIN tags t ON pt.tag_id = t.id
        LEFT JOIN reviews r ON p.id = r.product_id
        GROUP BY p.id, p.name, p.price, p.stock_quantity, c.name, pd.weight_kg,
                 pd.manufacturer, pd.warranty_months
        ORDER BY p.name
        """
		return self.connection.execute(q).fetchall()

	def get_supplier_statistics(self):
		q = """
        SELECT
            s.company_name,
            COUNT(ps.product_id) AS products_supplied,
            ROUND(AVG(ps.purchase_price), 2) AS avg_purchase_price,
            SUM(p.stock_quantity) AS total_stock
        FROM suppliers s
        LEFT JOIN product_suppliers ps ON s.id = ps.supplier_id
        LEFT JOIN products p ON ps.product_id = p.id
        GROUP BY s.id, s.company_name
        ORDER BY products_supplied DESC
        """
		return self.connection.execute(q).fetchall()

	def get_products_by_tag(self, tag_name: str):
		q = """
        SELECT
            p.name, p.price, c.name AS category_name,
            GROUP_CONCAT(DISTINCT t2.name) AS all_tags
        FROM products p
        INNER JOIN product_tags pt ON p.id = pt.product_id
        INNER JOIN tags t ON pt.tag_id = t.id
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN product_tags pt2 ON p.id = pt2.product_id
        LEFT JOIN tags t2 ON pt2.tag_id = t2.id
        WHERE t.name = ?
        GROUP BY p.id, p.name, p.price, c.name
        """
		return self.connection.execute(q, (tag_name,)).fetchall()

	def add_review(self, product_id: int, customer_id: int, rating: int, comment: str):
		q = "INSERT INTO reviews (product_id, customer_id, rating, comment) VALUES (?, ?, ?, ?)"
		try:
			with txn(self.connection):
				self.connection.execute(q, (product_id, customer_id, rating, comment))
			return True
		except sqlite3.Error as e:
			print(f"[ERROR] add_review failed: {e}")
			return False

	def upsert_product_supplier(self, product_id: int, supplier_id: int, purchase_price: float, delivery_days: int):
		"""Идемпотентное добавление/обновление записи связи M–M под транзакцией."""
		try:
			with txn(self.connection):
				self.connection.execute("""
                    INSERT INTO product_suppliers (product_id, supplier_id, purchase_price, delivery_days)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT(product_id, supplier_id)
                    DO UPDATE SET purchase_price=excluded.purchase_price,
                                  delivery_days=excluded.delivery_days
                """, (product_id, supplier_id, purchase_price, delivery_days))
			return True
		except sqlite3.Error as e:
			print(f"[ERROR] upsert_product_supplier failed: {e}")
			return False

	def category_analysis(self):
		q = """
        SELECT
            c.name AS category_name,
            COUNT(p.id) AS product_count,
            ROUND(AVG(p.price), 2) AS avg_price,
            MAX(p.price) AS max_price,
            MIN(p.price) AS min_price,
            SUM(p.stock_quantity) AS total_stock,
            COUNT(DISTINCT r.id) AS total_reviews,
            ROUND(AVG(r.rating), 2) AS avg_rating
        FROM categories c
        LEFT JOIN products p ON c.id = p.category_id
        LEFT JOIN reviews r ON p.id = r.product_id
        GROUP BY c.id, c.name
        ORDER BY product_count DESC
        """
		return self.connection.execute(q).fetchall()


def demonstrate():
	db = AdvancedDatabaseManager()
	db.connect()

	print("\n=== Продукты с полной информацией ===")
	for row in db.get_products_with_details():
		print(f"{row['name']} (${row['price']}) | Категория: {row['category_name']} | "
			  f"Теги: {row['tags']} | Рейтинг: {row['avg_rating']} ({row['review_count']} отзывов)")

	print("\n=== Статистика поставщиков ===")
	for s in db.get_supplier_statistics():
		print(f"{s['company_name']}: товаров={s['products_supplied']}, "
			  f"ср. закупка=${s['avg_purchase_price']}, запас={s['total_stock']}")

	print("\n=== Продукты с тегом 'новинка' ===")
	for p in db.get_products_by_tag('новинка'):
		print(f"{p['name']} - ${p['price']} ({p['category_name']}); все теги: {p['all_tags']}")

	print("\n=== Категории: аналитика ===")
	for c in db.category_analysis():
		print(f"{c['category_name']}: шт={c['product_count']}, "
			  f"avg=${c['avg_price']}, max=${c['max_price']}, min=${c['min_price']}, "
			  f"stock={c['total_stock']}, отзывы={c['total_reviews']}, рейтинг={c['avg_rating']}")

	ok = db.add_review(1, 3, 5, "Отличный продукт! Рекомендую!")
	print("\nДобавление отзыва:", "OK" if ok else "FAIL")

	ok2 = db.upsert_product_supplier(1, 1, 645.00, 6)
	print("Upsert product_suppliers:", "OK" if ok2 else "FAIL")

	db.close()


if __name__ == "__main__":
	demonstrate()
