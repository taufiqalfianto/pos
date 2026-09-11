import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  // Brand palette, drawn from the POS logo.
  static const Color primaryDark = Color(0xFF003BB8);
  static const Color primary = Color(0xFF006BFF);
  static const Color primaryLight = Color(0xFF1597FF);
  static const Color primarySoft = Color(0xFFEAF4FF);

  static const Color secondaryDark = Color(0xFF129A4A);
  static const Color secondary = Color(0xFF25C967);
  static const Color secondaryLight = Color(0xFF74E39B);
  static const Color secondarySoft = Color(0xFFEAFBF0);

  static const Color tertiaryDark = Color(0xFFD98600);
  static const Color tertiary = Color(0xFFFFB21A);
  static const Color tertiaryLight = Color(0xFFFFD36A);
  static const Color tertiarySoft = Color(0xFFFFF7E1);

  static const Color accent = secondary;
  static const Color info = Color(0xFF0B4EC9);

  // Neutral Palette
  static const Color background = Color(0xFFF4F8FF);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500

  // Status Colors
  static const Color success = secondaryDark;
  static const Color warning = tertiaryDark;
  static const Color error = Color(0xFFEF4444);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );

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
      color: (color ?? Colors.white).withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(borderRadius.r),
      border: Border.all(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        width: 2.w,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
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
