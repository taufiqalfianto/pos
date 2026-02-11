import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUsersTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS users');
      await _createUsersTable(db);
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN stock INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE products ADD COLUMN description TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 5) {
      await _createOrderTables(db);
    }
    if (oldVersion < 6) {
      await _createStockReportsTable(db);
    }
    if (oldVersion < 7) {
      await _createCategoriesTable(db);
      await db.execute('ALTER TABLE products ADD COLUMN category_id TEXT');
      // Set default category for existing products
      await db.insert('categories', {'id': 'general', 'name': 'Umum'});
      await db.execute(
        "UPDATE products SET category_id = 'general' WHERE category_id IS NULL",
      );
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE users ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE orders ADD COLUMN day INTEGER');
      await db.execute('ALTER TABLE orders ADD COLUMN month INTEGER');
      await db.execute('ALTER TABLE orders ADD COLUMN year INTEGER');

      // Populate existing orders with day, month, year from created_at
      final List<Map<String, dynamic>> orders = await db.query('orders');
      for (final order in orders) {
        final DateTime createdAt = DateTime.parse(order['created_at']);
        await db.update(
          'orders',
          {
            'day': createdAt.day,
            'month': createdAt.month,
            'year': createdAt.year,
          },
          where: 'id = ?',
          whereArgs: [order['id']],
        );
      }
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    // Table: Categories
    await _createCategoriesTable(db);

    // Table: Products
    await db.execute('''
CREATE TABLE products ( 
  id $idType, 
  name $textType,
  price $doubleType,
  image_path $textType,
  stock $intType,
  description $textType,
  is_synced $intType,
  category_id TEXT
  )
''');

    // Table: Users
    await _createUsersTable(db);

    // Table: Orders
    await _createOrderTables(db);

    // Table: Stock Reports
    await _createStockReportsTable(db);

    // Initial Data
    await db.insert('categories', {'id': 'general', 'name': 'Umum'});
  }

  Future _createUsersTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE users (
  id $idType,
  name $textType,
  username $textType UNIQUE,
  password $textType,
  image_path TEXT
)
''');
  }

  Future _createOrderTables(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE orders (
  id $idType,
  total_price $doubleType,
  created_at $textType,
  day $intType,
  month $intType,
  year $intType
)
''');

    await db.execute('''
CREATE TABLE order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id $textType,
  product_id $textType,
  product_name $textType,
  price $doubleType,
  quantity $intType,
  FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
)
''');
  }

  Future _createStockReportsTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE stock_reports (
  id $idType,
  product_id $textType,
  product_name $textType,
  system_stock $intType,
  manual_stock $intType,
  adjustment $intType,
  note $textType,
  created_at $textType
)
''');
  }

  Future _createCategoriesTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
