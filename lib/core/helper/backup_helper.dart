import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos/core/helper/app_logger.dart';
import 'package:pos/core/helper/database_helper.dart';
import 'package:pos/core/helper/file_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupCancelledException implements Exception {}

class BackupValidationException implements Exception {
  const BackupValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupExportResult {
  const BackupExportResult({
    required this.path,
    required this.tableCounts,
    required this.imageCount,
    required this.createdAt,
  });

  final String path;
  final Map<String, int> tableCounts;
  final int imageCount;
  final DateTime createdAt;
}

class BackupImportResult {
  const BackupImportResult({
    required this.tableCounts,
    required this.imageCount,
  });

  final Map<String, int> tableCounts;
  final int imageCount;
}

class BackupHelper {
  static const _format = 'premium_pos_backup';
  static const _formatVersion = 1;
  static const _lastBackupAtKey = 'last_backup_at';
  static const _logTag = 'Backup';

  static Future<BackupExportResult> exportBackup() async {
    AppLogger.info('Memulai export backup POS', tag: _logTag);
    final dbData = await DatabaseHelper.instance.exportTables();
    final packageInfo = await PackageInfo.fromPlatform();
    final imageNames = _collectImageNames(dbData);
    final createdAt = DateTime.now();
    final tableCounts = {
      for (final entry in dbData.entries) entry.key: entry.value.length,
    };

    AppLogger.info(
      'Data backup terkumpul: tables=$tableCounts, referenced_images=${imageNames.length}',
      tag: _logTag,
    );

    final archive = Archive();
    final payload = <String, dynamic>{
      'format': _format,
      'format_version': _formatVersion,
      'database_version': DatabaseHelper.databaseVersion,
      'created_at': createdAt.toIso8601String(),
      'app': {
        'name': packageInfo.appName,
        'package_name': packageInfo.packageName,
        'version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
      },
      'tables': dbData,
    };

    archive.addFile(
      ArchiveFile.string(
        'backup.json',
        const JsonEncoder.withIndent('  ').convert(payload),
      ),
    );

    var imageCount = 0;
    for (final imageName in imageNames) {
      final imagePath = FileHelper.getFullPath(imageName);
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) continue;

      final bytes = await imageFile.readAsBytes();
      archive.addFile(ArchiveFile('images/$imageName', bytes.length, bytes));
      imageCount++;
    }

    final zipBytes = ZipEncoder().encode(archive);

    final fileName = 'pos_backup_${_timestampForFileName()}.zip';
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Backup POS',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      bytes: Uint8List.fromList(zipBytes),
    );

    if (outputPath == null) {
      AppLogger.info('Export backup dibatalkan user', tag: _logTag);
      throw BackupCancelledException();
    }

    await saveLastBackupAt(createdAt);
    AppLogger.info(
      'Export backup berhasil: path=$outputPath, image_count=$imageCount, created_at=${createdAt.toIso8601String()}',
      tag: _logTag,
    );

    return BackupExportResult(
      path: outputPath,
      tableCounts: tableCounts,
      imageCount: imageCount,
      createdAt: createdAt,
    );
  }

  static Future<DateTime?> getLastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastBackupAtKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  static Future<void> saveLastBackupAt(DateTime dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupAtKey, dateTime.toIso8601String());
    AppLogger.debug(
      'Timestamp backup terakhir disimpan: ${dateTime.toIso8601String()}',
      tag: _logTag,
    );
  }

  static Future<BackupImportResult> importBackup() async {
    AppLogger.info('Memulai import backup POS', tag: _logTag);
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Backup POS',
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
    );

    final file = picked?.files.single;
    if (file == null) {
      AppLogger.info('Import backup dibatalkan user', tag: _logTag);
      throw BackupCancelledException();
    }

    AppLogger.info(
      'File backup dipilih: name=${file.name}, size=${file.size}',
      tag: _logTag,
    );
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final backupJson = _findArchiveFile(archive, 'backup.json');
    if (backupJson == null) {
      throw const BackupValidationException(
        'File backup tidak valid: backup.json tidak ditemukan.',
      );
    }

    final payload = jsonDecode(utf8.decode(_readArchiveFileBytes(backupJson)));
    if (payload is! Map<String, dynamic>) {
      throw const BackupValidationException('File backup tidak valid.');
    }

    _validatePayload(payload);
    final tables = _parseTables(payload['tables']);
    final tableCounts = {
      for (final entry in tables.entries) entry.key: entry.value.length,
    };
    AppLogger.info(
      'Payload backup valid: database_version=${payload['database_version']}, tables=$tableCounts',
      tag: _logTag,
    );
    final imageCount = await _restoreImagesAndRelink(archive, tables);
    AppLogger.info(
      'Gambar backup selesai direstore: image_count=$imageCount',
      tag: _logTag,
    );

    await DatabaseHelper.instance.replaceTables(tables);
    AppLogger.info('Restore database dari backup selesai', tag: _logTag);

    return BackupImportResult(tableCounts: tableCounts, imageCount: imageCount);
  }

  static Set<String> _collectImageNames(
    Map<String, List<Map<String, dynamic>>> tables,
  ) {
    final names = <String>{};
    for (final tableName in const ['users', 'products']) {
      for (final row in tables[tableName] ?? const <Map<String, dynamic>>[]) {
        final value = row['image_path'];
        if (value is String && value.trim().isNotEmpty) {
          names.add(_relativeImageName(value));
        }
      }
    }
    return names;
  }

  static void _validatePayload(Map<String, dynamic> payload) {
    if (payload['format'] != _format) {
      throw const BackupValidationException(
        'File backup bukan backup Premium POS.',
      );
    }
    if (payload['format_version'] != _formatVersion) {
      throw const BackupValidationException(
        'Versi format backup belum didukung oleh aplikasi ini.',
      );
    }

    final databaseVersion = payload['database_version'];
    if (databaseVersion is! int ||
        databaseVersion > DatabaseHelper.databaseVersion) {
      throw const BackupValidationException(
        'Versi database backup lebih baru dari aplikasi ini. Update aplikasi terlebih dahulu.',
      );
    }

    if (payload['tables'] is! Map<String, dynamic>) {
      throw const BackupValidationException('Data tabel backup tidak valid.');
    }
  }

  static Map<String, List<Map<String, dynamic>>> _parseTables(
    dynamic rawTables,
  ) {
    final tables = rawTables as Map<String, dynamic>;
    final parsed = <String, List<Map<String, dynamic>>>{};

    for (final tableName in DatabaseHelper.backupTableNames) {
      final rows = tables[tableName];
      if (rows is! List) {
        throw BackupValidationException(
          'Data tabel $tableName tidak ditemukan atau tidak valid.',
        );
      }

      parsed[tableName] = rows.map((row) {
        if (row is! Map<String, dynamic>) {
          throw BackupValidationException(
            'Baris tabel $tableName tidak valid.',
          );
        }

        return Map<String, dynamic>.from(row);
      }).toList();
    }

    return parsed;
  }

  static Future<int> _restoreImagesAndRelink(
    Archive archive,
    Map<String, List<Map<String, dynamic>>> tables,
  ) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    var imageCount = 0;

    for (final tableName in const ['users', 'products']) {
      for (final row in tables[tableName] ?? const <Map<String, dynamic>>[]) {
        final value = row['image_path'];
        if (value is! String || value.trim().isEmpty) continue;

        final imageName = _relativeImageName(value);
        final archiveFile = _findArchiveFile(archive, 'images/$imageName');
        if (archiveFile != null) {
          final target = File(p.join(documentsDir.path, imageName));
          await target.writeAsBytes(_readArchiveFileBytes(archiveFile));
          imageCount++;
        }

        row['image_path'] = imageName;
      }
    }

    return imageCount;
  }

  static ArchiveFile? _findArchiveFile(Archive archive, String name) {
    for (final file in archive.files) {
      if (file.isFile && file.name == name) return file;
    }
    return null;
  }

  static List<int> _readArchiveFileBytes(ArchiveFile file) {
    try {
      final bytes = file.readBytes();
      if (bytes == null) {
        throw const BackupValidationException('Gagal membaca isi file backup.');
      }
      return bytes;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Gagal membaca file di dalam backup',
        error: e,
        stackTrace: stackTrace,
      );
      throw const BackupValidationException('Gagal membaca isi file backup.');
    }
  }

  static String _relativeImageName(String value) => p.basename(value.trim());

  static String _timestampForFileName() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');

    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
