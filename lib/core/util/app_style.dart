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

class AppStyles {
  /// Radius kanonik kartu/panel konten dan semua tombol.
  static const double radiusCard = 20;

  /// Radius kanonik elemen kecil di dalam kartu (chip ikon, badge, tile).
  static const double radiusInner = 12;

  /// Kartu/panel konten standar: putih (atau [color]), radius [radiusCard],
  /// garis tipis 5% hitam, opsional bayangan premium.
  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    bool border = true,
    bool shadow = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radiusCard.r),
      border: border
          ? Border.all(color: Colors.black.withValues(alpha: 0.05))
          : null,
      boxShadow: shadow ? premiumShadow : null,
    );
  }

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
