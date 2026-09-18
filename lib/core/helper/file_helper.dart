import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'app_logger.dart';

class FileHelper {
  static const _logTag = 'FileHelper';
  static String? _basePath;

  /// Initializes the base path for storage.
  /// Should be called in main().
  static Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    _basePath = directory.path;
    AppLogger.info(
      'FileHelper initialized: base_path=$_basePath',
      tag: _logTag,
    );
  }

  static Future<String> saveImagePermanently(String temporaryPath) async {
    try {
      AppLogger.info('Simpan gambar permanen dimulai', tag: _logTag);
      final File tempFile = File(temporaryPath);
      if (!await tempFile.exists()) {
        AppLogger.warning(
          'File gambar sementara tidak ditemukan, memakai path asli',
          tag: _logTag,
        );
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
      AppLogger.info(
        'Simpan gambar permanen berhasil: file_name=$fileName',
        tag: _logTag,
      );
      return fileName;
    } catch (e) {
      AppLogger.error('Error saving image permanently', tag: _logTag, error: e);
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
