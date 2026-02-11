import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileHelper {
  static String? _basePath;

  /// Initializes the base path for storage.
  /// Should be called in main().
  static Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    _basePath = directory.path;
  }

  static Future<String> saveImagePermanently(String temporaryPath) async {
    try {
      final File tempFile = File(temporaryPath);
      if (!await tempFile.exists()) {
        return temporaryPath;
      }

      if (_basePath == null) await initialize();

      // Create a unique filename
      final String ext = extension(temporaryPath);
      final String fileName = '${const Uuid().v4()}$ext';

      // Copy the file to the new location
      final String permanentPath = join(_basePath!, fileName);
      await tempFile.copy(permanentPath);

      // Return ONLY the filename for relative storage
      return fileName;
    } catch (e) {
      print('Error saving image permanently: $e');
      return temporaryPath;
    }
  }

  /// Constructs the full absolute path from a relative path or filename.
  /// Handles legacy absolute paths by extracting the filename if needed.
  static String getFullPath(String? path) {
    if (path == null || path.isEmpty) return '';

    // If it's already an absolute path (legacy data), try to extract filename
    // or return as is if it's not in the documents directory.
    if (path.contains('/') || path.contains('\\')) {
      final fileName = basename(path);
      if (_basePath != null) {
        final newPath = join(_basePath!, fileName);
        if (File(newPath).existsSync()) return newPath;
      }
      return path; // Fallback to original absolute path
    }

    if (_basePath == null) return path;
    return join(_basePath!, path);
  }

  static Future<bool> fileExists(String path) async {
    if (path.isEmpty) return false;
    final fullPath = getFullPath(path);
    return await File(fullPath).exists();
  }
}
