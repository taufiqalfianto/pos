import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/helper/app_logger.dart';
import '../../../core/helper/database_helper.dart';
import '../../../core/helper/security_helper.dart';
import '../data/model/user_model.dart';

class AuthRepository {
  static const _logTag = 'AuthRepository';
  final DatabaseHelper _dbHelper;
  static const String _userKey = 'current_user_id';

  AuthRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> register(UserModel user) async {
    AppLogger.info('Register user dimulai: user_id=${user.id}', tag: _logTag);
    final db = await _dbHelper.database;
    final hashedUser = user.copyWith(
      password: SecurityHelper.hashPassword(user.password),
    );
    await db.insert('users', hashedUser.toMap());
    AppLogger.info('Register user berhasil: user_id=${user.id}', tag: _logTag);
  }

  Future<UserModel?> login(String username, String password) async {
    AppLogger.info('Login dimulai untuk username=$username', tag: _logTag);
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
      AppLogger.info('Login berhasil: user_id=${user.id}', tag: _logTag);
      return user;
    }
    AppLogger.warning('Login gagal: username tidak cocok', tag: _logTag);
    return null;
  }

  Future<void> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    AppLogger.info('Ganti password dimulai: user_id=$userId', tag: _logTag);
    final db = await _dbHelper.database;
    final hashedOldPassword = SecurityHelper.hashPassword(oldPassword);

    final userResult = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [userId, hashedOldPassword],
    );
    if (userResult.isEmpty) {
      AppLogger.warning(
        'Ganti password ditolak: user_id=$userId',
        tag: _logTag,
      );
      throw Exception('Password lama salah');
    }

    final hashedNewPassword = SecurityHelper.hashPassword(newPassword);
    await db.update(
      'users',
      {'password': hashedNewPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
    AppLogger.info('Ganti password berhasil: user_id=$userId', tag: _logTag);
  }

  Future<UserModel?> getCurrentUser() async {
    AppLogger.debug('Memeriksa sesi user aktif', tag: _logTag);
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
        AppLogger.debug('Sesi user ditemukan: user_id=$userId', tag: _logTag);
        return UserModel.fromMap(result.first);
      }
      AppLogger.warning(
        'Session user_id tidak ditemukan di database: user_id=$userId',
        tag: _logTag,
      );
    }
    AppLogger.debug('Tidak ada sesi user aktif', tag: _logTag);
    return null;
  }

  Future<void> logout() async {
    AppLogger.info('Logout dimulai', tag: _logTag);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    AppLogger.info('Logout berhasil', tag: _logTag);
  }

  Future<void> updateProfile(UserModel user) async {
    AppLogger.info('Update profil dimulai: user_id=${user.id}', tag: _logTag);
    final db = await _dbHelper.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    AppLogger.info('Update profil berhasil: user_id=${user.id}', tag: _logTag);
  }

  Future<void> saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userId);
    AppLogger.debug('Session disimpan: user_id=$userId', tag: _logTag);
  }
}
