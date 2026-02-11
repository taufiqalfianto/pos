import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/helper/database_helper.dart';
import '../../../core/helper/security_helper.dart';
import '../data/model/user_model.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper;
  static const String _userKey = 'current_user_id';

  AuthRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> register(UserModel user) async {
    final db = await _dbHelper.database;
    final hashedUser = user.copyWith(
      password: SecurityHelper.hashPassword(user.password),
    );
    await db.insert('users', hashedUser.toMap());
  }

  Future<UserModel?> login(String username, String password) async {
    final db = await _dbHelper.database;
    final hashedPassword = SecurityHelper.hashPassword(password);
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );

    if (result.isNotEmpty) {
      final user = UserModel.fromMap(result.first);
      await saveSession(user.id);
      return user;
    }
    return null;
  }

  Future<void> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    final db = await _dbHelper.database;
    final hashedOldPassword = SecurityHelper.hashPassword(oldPassword);

    final userResult = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [userId, hashedOldPassword],
    );
    if (userResult.isEmpty) {
      throw Exception('Password lama salah');
    }

    final hashedNewPassword = SecurityHelper.hashPassword(newPassword);
    await db.update(
      'users',
      {'password': hashedNewPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userKey);

    if (userId != null) {
      final db = await _dbHelper.database;
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (result.isNotEmpty) {
        return UserModel.fromMap(result.first);
      }
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<void> updateProfile(UserModel user) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userId);
  }
}
