import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../../../core/helper/app_logger.dart';
import '../../../core/helper/backup_helper.dart';
import '../../../core/helper/database_helper.dart';
import '../data/model/product_model.dart';
import '../data/model/stock_report_model.dart';

class ProductRepository {
  static const _logTag = 'ProductRepository';
  final DatabaseHelper _dbHelper;

  ProductRepository() : _dbHelper = DatabaseHelper.instance;

  // Stream for real-time updates
  final _productUpdateController = StreamController<void>.broadcast();
  Stream<void> get productUpdates => _productUpdateController.stream;

  void notifyListeners() {
    AppLogger.debug('Notify product listeners', tag: _logTag);
    _productUpdateController.add(null);
  }

  void dispose() {
    AppLogger.debug('Dispose product repository stream', tag: _logTag);
    _productUpdateController.close();
  }

  // 7. Save Stock Report
  Future<void> saveStockReport(StockReportModel report) async {
    AppLogger.info(
      'Simpan laporan stok dimulai: report_id=${report.id}, product_id=${report.productId}',
      tag: _logTag,
    );
    final db = await _dbHelper.database;
    await db.insert(
      'stock_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // After saving report, update the product's actual stock
    await updateStock(report.productId, report.manualStock);
    AppLogger.info(
      'Simpan laporan stok berhasil: report_id=${report.id}, adjustment=${report.adjustment}',
      tag: _logTag,
    );
    notifyListeners();
  }

  // 8. Get Stock Reports for a Product
  Future<List<StockReportModel>> getStockReports(String productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_reports',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    AppLogger.debug(
      'Riwayat stok dimuat: product_id=$productId, count=${result.length}',
      tag: _logTag,
    );
    return result.map((json) => StockReportModel.fromMap(json)).toList();
  }

  // 9. Update Stock Directly (Manual Reconciliation)
  Future<void> updateStock(String id, int quantity) async {
    AppLogger.info(
      'Update stok dimulai: product_id=$id, quantity=$quantity',
      tag: _logTag,
    );
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      final product = ProductModel.fromMap(result.first);
      await db.update(
        'products',
        product.copyWith(stock: quantity, isSynced: 0).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      // Mock sync
      try {
        await Future.delayed(const Duration(milliseconds: 300));
        await db.update(
          'products',
          product.copyWith(stock: quantity, isSynced: 1).toMap(),
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (e) {
        AppLogger.error('Manual stock update sync gagal', error: e);
      }
      AppLogger.info(
        'Update stok berhasil: product_id=$id, quantity=$quantity',
        tag: _logTag,
      );
      notifyListeners();
    } else {
      AppLogger.warning(
        'Update stok dilewati: product tidak ditemukan, product_id=$id',
        tag: _logTag,
      );
    }
  }

  // 1. Get All Products (Local First)
  Future<List<ProductModel>> getProducts() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT p.*, c.name as category_name 
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      ORDER BY p.name ASC
    ''');
    AppLogger.debug('Produk dimuat: count=${result.length}', tag: _logTag);
    return result.map((json) {
      return ProductModel.fromMap(
        json,
        categoryName: json['category_name'] as String?,
      );
    }).toList();
  }

  // 2. Add Product (Offline First + Auto Sync)
  Future<void> addProduct(ProductModel product) async {
    AppLogger.info(
      'Tambah produk dimulai: product_id=${product.id}',
      tag: _logTag,
    );
    final db = await _dbHelper.database;

    // Step A: Simpan ke Local DB (status not synced)
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Step B: Coba kirim ke Server (Fire & Forget logic or Await)
    try {
      // Simulasi network call
      // await _dio.post(_baseUrl, data: product.toJson());
      await Future.delayed(const Duration(seconds: 1)); // Mock delay

      // Jika sukses, update status is_synced = 1
      await db.update(
        'products',
        product.copyWith(isSynced: 1).toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    } catch (e) {
      // Jika gagal (offline/error), biarkan is_synced = 0
      AppLogger.error('Sync gagal, data tersimpan lokal', error: e);
    }
    AppLogger.info(
      'Tambah produk berhasil: product_id=${product.id}',
      tag: _logTag,
    );
    notifyListeners();
  }

  // 3. Manual Sync (Mengirim semua data yang pending)
  Future<void> syncPendingData() async {
    AppLogger.info('Sync pending produk dimulai', tag: _logTag);
    final db = await _dbHelper.database;

    // Ambil data yang belum sync
    final pendingData = await db.query(
      'products',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    AppLogger.info(
      'Produk pending sync ditemukan: count=${pendingData.length}',
      tag: _logTag,
    );

    for (var map in pendingData) {
      final product = ProductModel.fromMap(map);
      try {
        // await _dio.post(_baseUrl, data: product.toJson());
        await Future.delayed(const Duration(milliseconds: 500)); // Mock delay

        // Update status jadi synced
        await db.update(
          'products',
          product.copyWith(isSynced: 1).toMap(),
          where: 'id = ?',
          whereArgs: [product.id],
        );
        AppLogger.debug(
          'Produk pending berhasil disync: product_id=${product.id}',
          tag: _logTag,
        );
      } catch (e) {
        AppLogger.error('Gagal sync item ${product.name}', error: e);
      }
    }
    AppLogger.info('Sync pending produk selesai', tag: _logTag);
    notifyListeners();
  }

  Future<DateTime> createBackupSync() async {
    AppLogger.info('Backup dashboard dimulai', tag: 'DashboardBackup');
    final result = await BackupHelper.exportBackup();
    AppLogger.info(
      'Backup dashboard selesai: created_at=${result.createdAt.toIso8601String()}, image_count=${result.imageCount}',
      tag: 'DashboardBackup',
    );
    return result.createdAt;
  }

  Future<DateTime?> getLastSyncAt() => BackupHelper.getLastBackupAt();

  // 4. Update Product
  Future<void> updateProduct(ProductModel product) async {
    AppLogger.info(
      'Update produk dimulai: product_id=${product.id}',
      tag: _logTag,
    );
    final db = await _dbHelper.database;
    await db.update(
      'products',
      product.copyWith(isSynced: 0).toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );

    // Mock sync after update
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await db.update(
        'products',
        product.copyWith(isSynced: 1).toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    } catch (e) {
      AppLogger.error('Update sync gagal', error: e);
    }
    AppLogger.info(
      'Update produk berhasil: product_id=${product.id}',
      tag: _logTag,
    );
    notifyListeners();
  }

  // 5. Delete Product
  Future<void> deleteProduct(String id) async {
    AppLogger.info('Hapus produk dimulai: product_id=$id', tag: _logTag);
    final db = await _dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);

    // In real app, we would also hit the API to delete
    try {
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      AppLogger.error('Delete sync gagal', error: e);
    }
    AppLogger.info('Hapus produk berhasil: product_id=$id', tag: _logTag);
    notifyListeners();
  }

  // 6. Reduce Stock
  Future<void> reduceStock(String id, int quantity) async {
    AppLogger.info(
      'Kurangi stok dimulai: product_id=$id, quantity=$quantity',
      tag: _logTag,
    );
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      final product = ProductModel.fromMap(result.first);
      final newStock = product.stock - quantity;

      if (newStock < 0) {
        AppLogger.warning(
          'Kurangi stok ditolak: product_id=$id, requested=$quantity, stock=${product.stock}',
          tag: _logTag,
        );
        throw Exception('Stok untuk "${product.name}" tidak mencukupi');
      }

      await db.update(
        'products',
        product.copyWith(stock: newStock, isSynced: 0).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      // Mock sync after stock change
      try {
        await Future.delayed(const Duration(milliseconds: 300));
        await db.update(
          'products',
          product.copyWith(stock: newStock, isSynced: 1).toMap(),
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (e) {
        AppLogger.error('Stock update sync gagal', error: e);
      }
      AppLogger.info(
        'Kurangi stok berhasil: product_id=$id, quantity=$quantity, new_stock=$newStock',
        tag: _logTag,
      );
      notifyListeners();
    } else {
      AppLogger.warning(
        'Kurangi stok dilewati: product tidak ditemukan, product_id=$id',
        tag: _logTag,
      );
    }
  }

  // 10. Get Product By ID
  Future<ProductModel?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      AppLogger.debug('Produk ditemukan: product_id=$id', tag: _logTag);
      return ProductModel.fromMap(result.first);
    }
    AppLogger.warning('Produk tidak ditemukan: product_id=$id', tag: _logTag);
    return null;
  }
}
