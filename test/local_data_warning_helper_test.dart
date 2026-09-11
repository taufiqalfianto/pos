import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos/core/helper/local_data_warning_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Premium POS',
      packageName: 'com.example.pos',
      version: '1.0.0',
      buildNumber: '12',
      buildSignature: '',
    );
  });

  test(
    'warning tampil sebelum user menerima versi aplikasi saat ini',
    () async {
      expect(await LocalDataWarningHelper.shouldShowWarning(), isTrue);
    },
  );

  test(
    'warning tidak tampil lagi setelah diterima untuk versi yang sama',
    () async {
      await LocalDataWarningHelper.acceptWarning();

      expect(await LocalDataWarningHelper.shouldShowWarning(), isFalse);
    },
  );
}
