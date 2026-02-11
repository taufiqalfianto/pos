import 'dart:async';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/helper/database_helper.dart';
import '../data/model/product_model.dart';

import '../data/model/stock_report_model.dart';

class ProductRepository {
  final Dio _dio;
  final DatabaseHelper _dbHelper;

  // Ganti dengan URL API Anda (gunakan IP lokal jika emulator: 10.0.2.2)
  final String _baseUrl = 'https://api.example.com/products';

  ProductRepository({Dio? dio})
    : _dio = dio ?? Dio(),
      _dbHelper = DatabaseHelper.instance;

  // Stream for real-time updates
  final _productUpdateController = StreamController<void>.broadcast();
  Stream<void> get productUpdates => _productUpdateController.stream;

  void notifyListeners() {
    _productUpdateController.add(null);
  }

  void dispose() {
    _productUpdateController.close();
  }

  // 7. Save Stock Report
  Future<void> saveStockReport(StockReportModel report) async {
    final db = await _dbHelper.database;
    await db.insert(
      'stock_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // After saving report, update the product's actual stock
    await updateStock(report.productId, report.manualStock);
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
    return result.map((json) => StockReportModel.fromMap(json)).toList();
  }

  // 9. Update Stock Directly (Manual Reconciliation)
  Future<void> updateStock(String id, int quantity) async {
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
        print("Manual stock update sync gagal: $e");
      }
      notifyListeners();
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
    return result.map((json) {
      return ProductModel.fromMap(
        json,
        categoryName: json['category_name'] as String?,
      );
    }).toList();
  }

  // 2. Add Product (Offline First + Auto Sync)
  Future<void> addProduct(ProductModel product) async {
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
      print("Sync gagal, data tersimpan lokal: $e");
    }
    notifyListeners();
  }

  // 3. Manual Sync (Mengirim semua data yang pending)
  Future<void> syncPendingData() async {
    final db = await _dbHelper.database;

    // Ambil data yang belum sync
    final pendingData = await db.query(
      'products',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    if (pendingData.isEmpty) return;

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
      } catch (e) {
        print("Gagal sync item ${product.name}");
      }
    }
    notifyListeners();
  }

  // 4. Update Product
  Future<void> updateProduct(ProductModel product) async {
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
      print("Update sync gagal: $e");
    }
    notifyListeners();
  }

  // 5. Delete Product
  Future<void> deleteProduct(String id) async {
    final db = await _dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);

    // In real app, we would also hit the API to delete
    try {
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print("Delete sync gagal: $e");
    }
    notifyListeners();
  }

  // 6. Reduce Stock
  Future<void> reduceStock(String id, int quantity) async {
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
        print("Stock update sync gagal: $e");
      }
      notifyListeners();
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
      return ProductModel.fromMap(result.first);
    }
    return null;
  }
}
