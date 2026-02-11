import 'package:sqflite/sqflite.dart';
import '../../../core/helper/database_helper.dart';
import '../data/model/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<CategoryModel>> getCategories() async {
    final db = await _dbHelper.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCategory(String id) async {
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
  }
}
