import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color accent = Color(0xFF22D3EE); // Cyan

  // Neutral Palette
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Glassmorphic Gradients
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white60, Colors.white10],
  );
}

/// Design tokens terpusat, diskalakan ScreenUtil terhadap designSize (393 × 852)
/// sehingga proporsi tetap konsisten di semua ukuran device.
class AppDimens {
  // Tinggi tombol
  static double get buttonHeight => 56.w;
  static double get buttonHeightSmall => 44.w;

  // Radius
  static double get radiusSmall => 12.r;
  static double get radiusMedium => 18.r;
  static double get radiusLarge => 24.r;

  // Jarak vertikal antar elemen
  static double get spaceXs => 4.h;
  static double get spaceSm => 8.h;
  static double get spaceMd => 16.h;
  static double get spaceLg => 24.h;
  static double get spaceXl => 32.h;

  // Padding standar halaman
  static double get pagePadding => 20.w;
  static double get cardPadding => 20.w;
  static double get inputPaddingH => 20.w;
  static double get inputPaddingV => 16.h;

  // Ukuran font, minTextAdapt=true agar tidak mengecil berlebihan
  static double get fontCaption => 11.sp;
  static double get fontBodySm => 13.sp;
  static double get fontBody => 14.sp;
  static double get fontSubtitle => 16.sp;
  static double get fontTitle => 18.sp;
  static double get fontHeading => 20.sp;
  static double get fontDisplay => 24.sp;
}

class AppStyles {
  static BoxDecoration glassDecoration({
    double borderRadius = 24.0,
    Color? color,
    double blur = 10.0,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(0.7),
      borderRadius: BorderRadius.circular(borderRadius.r),
      border: Border.all(color: Colors.deepPurple.withOpacity(0.2), width: 2.w),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20.r,
          offset: Offset(0, 8.h),
        ),
      ],
    );
  }

  static const List<BoxShadow> premiumShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x05000000), blurRadius: 40, offset: Offset(0, 20)),
  ];

  static TextStyle get titleStyle => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get subtitleStyle => TextStyle(
    fontSize: 14.sp,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );
}
