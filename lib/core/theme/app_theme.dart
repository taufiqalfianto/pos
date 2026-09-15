import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  /// Bentuk kanonik semua tombol: radius [AppStyles.radiusCard].
  static final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppStyles.radiusCard.r),
  );

  /// Tipografi kanonik tombol, diturunkan dari textTheme runtime agar font
  /// family tema (Poppins, atau Roboto di test) ikut terbawa.
  static TextStyle buttonTextStyle(TextTheme textTheme) =>
      textTheme.labelLarge!.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      );

  static ThemeData lightTheme(BuildContext context) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.isTablet(context);

    // Material default pada Flutter versi ini memberi fontSize null untuk
    // semua role textTheme, sehingga TextTheme.apply(fontSizeFactor:) gagal
    // dan teks tema tidak ikut skala orientasi. Tetapkan ukuran eksplisit
    // `.sp` (standar Material 3) agar semua role mengikuti skala global
    // (AppBreakpointResolver.fontScaleFor).
    final base = GoogleFonts.poppinsTextTheme();

    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondarySoft,
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: AppColors.tertiarySoft,
      onTertiaryContainer: AppColors.tertiaryDark,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusCard.r),
        ),
        color: Colors.white,
        surfaceTintColor: AppColors.primarySoft,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        // Tablet: field sedikit lebih lega supaya target sentuh tetap nyaman
        // walau `.h` landskap tablet hanya ~0.9-1.5x.
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18.w : (isLandscape ? 16.w : 20.w),
          vertical: isTablet ? 14.h : (isLandscape ? 10.h : 16.h),
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
          borderSide: BorderSide(color: AppColors.primary, width: 2.w),
        ),
      ),
      // Semua varian tombol memakai radius kanonik yang sama, sehingga tidak
      // perlu lagi `shape:` per pemanggilan. Tipografi tombol diambil dari
      // textTheme (bukan ditempel di sini) supaya override font theme tetap
      // terbawa; lihat [buttonTextStyle].
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primarySoft,
          disabledForegroundColor: AppColors.textSecondary,
          shape: buttonShape,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: buttonShape,
          side: const BorderSide(color: AppColors.primary),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.primarySoft,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      visualDensity: (isLandscape || isTablet)
          ? VisualDensity.compact
          : VisualDensity.standard,
    );
  }
}
