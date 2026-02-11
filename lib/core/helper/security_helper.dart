import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityHelper {
  /// Hashes a password using SHA-256.
  /// This is a one-way process.
  static String hashPassword(String password) {
    if (password.isEmpty) return '';
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
