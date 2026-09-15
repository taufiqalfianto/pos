import 'package:flutter/material.dart';
import 'package:pos/core/util/app_style.dart';

/// AppBar global aplikasi: background primary + teks/ikon putih.
///
/// Dipakai di semua `Scaffold` supaya gaya app bar seragam; detail lain
/// (tinggi, judul, spacing) mengikuti `appBarTheme` di [AppTheme].
class AppAppBar extends AppBar {
  AppAppBar({
    super.key,
    super.title,
    super.actions,
    super.leading,
    super.bottom,
    super.flexibleSpace,
    super.automaticallyImplyLeading,
  }) : super(
         backgroundColor: AppColors.primary,
         foregroundColor: Colors.white,
         elevation: 0,
         centerTitle: true,
         surfaceTintColor: Colors.transparent,
       );
}
