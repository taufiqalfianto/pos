import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataWarningHelper {
  static const _acceptedVersionKey = 'accepted_local_data_warning_version';

  static Future<String> _currentVersionKey() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  static Future<bool> shouldShowWarning() async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = await _currentVersionKey();
    return prefs.getString(_acceptedVersionKey) != currentVersion;
  }

  static Future<void> acceptWarning() async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = await _currentVersionKey();
    await prefs.setString(_acceptedVersionKey, currentVersion);
  }
}
