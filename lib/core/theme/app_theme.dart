import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.isTablet(context);

    // Material default pada Flutter versi ini memberi fontSize null untuk
    // semua role textTheme, sehingga TextTheme.apply(fontSizeFactor:) gagal
    // dan teks tema tidak ikut skala orientasi. Tetapkan ukuran eksplisit
    // `.sp` (standar Material 3) agar semua role mengikuti skala global
    // (AppBreakpointResolver.fontScaleFor).
    final base = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base.copyWith(
        displayLarge: AppStyles.titleStyle,
        titleLarge: AppStyles.titleStyle.copyWith(fontSize: 20.sp),
        displayMedium: base.displayMedium?.copyWith(fontSize: 45.sp),
        displaySmall: base.displaySmall?.copyWith(fontSize: 36.sp),
        headlineLarge: base.headlineLarge?.copyWith(fontSize: 32.sp),
        headlineMedium: base.headlineMedium?.copyWith(fontSize: 28.sp),
        headlineSmall: base.headlineSmall?.copyWith(fontSize: 24.sp),
        titleMedium: base.titleMedium?.copyWith(fontSize: 16.sp),
        titleSmall: base.titleSmall?.copyWith(fontSize: 14.sp),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: 16.sp),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: 14.sp),
        bodySmall: base.bodySmall?.copyWith(fontSize: 12.sp),
        labelLarge: base.labelLarge?.copyWith(fontSize: 14.sp),
        labelMedium: base.labelMedium?.copyWith(fontSize: 12.sp),
        labelSmall: base.labelSmall?.copyWith(fontSize: 11.sp),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isLandscape || isTablet ? 16 : 20,
          vertical: isLandscape || isTablet ? 10 : 16,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      visualDensity: (isLandscape || isTablet)
          ? VisualDensity.compact
          : VisualDensity.standard,
    );
  }
}
