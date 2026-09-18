import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pos/app.dart';
import 'package:pos/core/helper/app_logger.dart';
import 'package:pos/core/helper/file_helper.dart';
import 'package:pos/features/auth/cubit/auth_cubit.dart';
import 'package:pos/features/auth/repository/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('Aplikasi POS mulai diinisialisasi', tag: 'AppLifecycle');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  AppLogger.debug('Orientasi layar dikonfigurasi', tag: 'AppLifecycle');
  await initializeDateFormatting('id', null);
  AppLogger.debug('Date formatting locale id siap', tag: 'AppLifecycle');
  await FileHelper.initialize();
  AppLogger.debug('FileHelper siap', tag: 'AppLifecycle');

  final authRepository = AuthRepository();
  final authCubit = AuthCubit(authRepository);

  AppLogger.info('Menjalankan PosApp', tag: 'AppLifecycle');
  runApp(PosApp(authCubit: authCubit));
}
