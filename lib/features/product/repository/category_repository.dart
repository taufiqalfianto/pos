import 'package:sqflite/sqflite.dart';
import '../../../core/helper/app_logger.dart';
import '../../../core/helper/database_helper.dart';
import '../data/model/category_model.dart';

class CategoryRepository {
  static const _logTag = 'CategoryRepository';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<CategoryModel>> getCategories() async {
    final db = await _dbHelper.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    AppLogger.debug('Kategori dimuat: count=${result.length}', tag: _logTag);
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    AppLogger.info('Tambah kategori dimulai: id=${category.id}', tag: _logTag);
    final db = await _dbHelper.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.info('Tambah kategori berhasil: id=${category.id}', tag: _logTag);
  }

  Future<void> deleteCategory(String id) async {
    AppLogger.info('Hapus kategori dimulai: id=$id', tag: _logTag);
    final db = await _dbHelper.database;
    // When deleting a category, move products back to 'general'
    await db.transaction((txn) async {
      await txn.update(
        'products',
        {'category_id': 'general'},
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
    AppLogger.info('Hapus kategori berhasil: id=$id', tag: _logTag);
  }
}
