import 'dart:io';

import 'package:pos/core/helper/app_logger.dart';
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
    await _backupDatabaseBeforeOpen(path);

    return await openDatabase(
      path,
      version: 12,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUsersTable(db);
    }
    if (oldVersion < 3) {
      await _createUsersTable(db);
    }
    if (oldVersion < 4) {
      await _addColumnIfMissing(
        db,
        tableName: 'products',
        columnName: 'stock',
        definition: 'INTEGER NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        tableName: 'products',
        columnName: 'description',
        definition: 'TEXT NOT NULL DEFAULT ""',
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
      await _addColumnIfMissing(
        db,
        tableName: 'products',
        columnName: 'category_id',
        definition: 'TEXT',
      );
      // Set default category for existing products
      await db.insert('categories', {
        'id': 'general',
        'name': 'Umum',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.execute(
        "UPDATE products SET category_id = 'general' WHERE category_id IS NULL",
      );
    }
    if (oldVersion < 8) {
      await _addColumnIfMissing(
        db,
        tableName: 'users',
        columnName: 'image_path',
        definition: 'TEXT',
      );
    }
    if (oldVersion < 9) {
      await _addColumnIfMissing(
        db,
        tableName: 'orders',
        columnName: 'day',
        definition: 'INTEGER NOT NULL DEFAULT 1',
      );
      await _addColumnIfMissing(
        db,
        tableName: 'orders',
        columnName: 'month',
        definition: 'INTEGER NOT NULL DEFAULT 1',
      );
      await _addColumnIfMissing(
        db,
        tableName: 'orders',
        columnName: 'year',
        definition: 'INTEGER NOT NULL DEFAULT 1970',
      );

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
    if (oldVersion < 10) {
      await _addColumnIfMissing(
        db,
        tableName: 'products',
        columnName: 'cost_price',
        definition: 'REAL NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        tableName: 'order_items',
        columnName: 'cost_price',
        definition: 'REAL NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 11) {
      await _createIndexes(db);
    }
    if (oldVersion < 12) {
      await _addColumnIfMissing(
        db,
        tableName: 'orders',
        columnName: 'payment_method',
        definition: 'TEXT NOT NULL DEFAULT "cash"',
      );
    }
    await _ensureCurrentSchema(db);
  }

  Future<void> _backupDatabaseBeforeOpen(String path) async {
    try {
      await _copyIfExists(path, '$path.backup');
      await _copyIfExists('$path-wal', '$path-wal.backup');
      await _copyIfExists('$path-shm', '$path-shm.backup');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Backup database lokal sebelum open gagal',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _copyIfExists(String sourcePath, String targetPath) async {
    final source = File(sourcePath);
    if (await source.exists()) {
      await source.copy(targetPath);
    }
  }

  Future<void> _ensureCurrentSchema(Database db) async {
    await _createCategoriesTable(db);
    await _createProductsTable(db);
    await _createUsersTable(db);
    await _createOrderTables(db);
    await _createStockReportsTable(db);
    await _addColumnIfMissing(
      db,
      tableName: 'products',
      columnName: 'stock',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'products',
      columnName: 'description',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'products',
      columnName: 'category_id',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'products',
      columnName: 'cost_price',
      definition: 'REAL NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'users',
      columnName: 'image_path',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'orders',
      columnName: 'day',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'orders',
      columnName: 'month',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'orders',
      columnName: 'year',
      definition: 'INTEGER NOT NULL DEFAULT 1970',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'orders',
      columnName: 'payment_method',
      definition: 'TEXT NOT NULL DEFAULT "cash"',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'order_items',
      columnName: 'cost_price',
      definition: 'REAL NOT NULL DEFAULT 0',
    );
    await db.insert('categories', {
      'id': 'general',
      'name': 'Umum',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await _createIndexes(db);
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String tableName,
    required String columnName,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final hasColumn = columns.any((column) => column['name'] == columnName);

    if (!hasColumn) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $definition',
      );
    }
  }

  Future _createDB(Database db, int version) async {
    // Table: Categories
    await _createCategoriesTable(db);

    // Table: Products
    await _createProductsTable(db);

    // Table: Users
    await _createUsersTable(db);

    // Table: Orders
    await _createOrderTables(db);

    // Table: Stock Reports
    await _createStockReportsTable(db);

    // Create Indexes
    await _createIndexes(db);

    // Initial Data
    await db.insert('categories', {
      'id': 'general',
      'name': 'Umum',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items (order_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders (created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_orders_date ON orders (year, month, day)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_category ON products (category_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_synced ON products (is_synced)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_reports_product ON stock_reports (product_id)',
    );
  }

  Future _createProductsTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE IF NOT EXISTS products (
  id $idType,
  name $textType,
  price $doubleType,
  cost_price $doubleType,
  image_path $textType,
  stock $intType,
  description $textType,
  is_synced $intType,
  category_id TEXT
  )
''');
  }

  Future _createUsersTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE IF NOT EXISTS users (
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
CREATE TABLE IF NOT EXISTS orders (
  id $idType,
  total_price $doubleType,
  payment_method $textType,
  created_at $textType,
  day $intType,
  month $intType,
  year $intType
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id $textType,
  product_id $textType,
  product_name $textType,
  price $doubleType,
  cost_price $doubleType,
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
CREATE TABLE IF NOT EXISTS stock_reports (
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
CREATE TABLE IF NOT EXISTS categories (
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
