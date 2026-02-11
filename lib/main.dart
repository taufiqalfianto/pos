import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pos/app.dart';
import 'package:pos/core/helper/file_helper.dart';
import 'package:pos/features/auth/cubit/auth_cubit.dart';
import 'package:pos/features/auth/repository/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  await FileHelper.initialize();

  final authRepository = AuthRepository();
  final authCubit = AuthCubit(authRepository);

  runApp(PosApp(authCubit: authCubit));
}
