import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Breakpoint sesuai dokumen teknis responsif:
///
/// | Class              | Lebar        |
/// |--------------------|--------------|
/// | mobileSmall        | < 360px      |
/// | mobile             | 360px–599px  |
/// | tabletPortrait     | 600px–839px  |
/// | tabletLandscape    | >= 840px     |
enum AppBreakpoint { mobileSmall, mobile, tabletPortrait, tabletLandscape }

/// Resolver breakpoint murni dari lebar (tanpa BuildContext), mudah di-test.
abstract final class AppBreakpointResolver {
  static const double mobileMin = 360;
  static const double tabletMin = 600;
  static const double tabletLandscapeMin = 840;

  static AppBreakpoint fromWidth(double width) {
    if (width < mobileMin) return AppBreakpoint.mobileSmall;
    if (width < tabletMin) return AppBreakpoint.mobile;
    if (width < tabletLandscapeMin) return AppBreakpoint.tabletPortrait;
    return AppBreakpoint.tabletLandscape;
  }

  /// Faktor skala font global per breakpoint & orientasi, supaya semua teks
  /// (`.sp`, tema, tombol, drawer) bergeser bersama-sama saat layar berubah:
  /// mobile portrait 1.0 · mobile landscape 0.9 · tablet portrait 1.0 ·
  /// tablet landscape / wide 0.95 · desktop 1.0.
  static double fontScaleFor(double width, double height) {
    if (width >= 1200) return 1.0;
    if (width >= tabletLandscapeMin) return 0.95;
    // Layar lebar & pendek (lebar > tinggi) = ponsel landscape, kecilkan font.
    if (width >= tabletMin && width <= height) return 1.0;
    if (width > height) return 0.9;
    return 1.0;
  }
}

class ResponsiveCondition {
  final MediaQueryData _mediaQuery;

  const ResponsiveCondition._(this._mediaQuery);

  factory ResponsiveCondition.of(BuildContext context) {
    return ResponsiveCondition._(MediaQuery.of(context));
  }

  Orientation get orientation => _mediaQuery.orientation;

  bool get isLandscape => orientation == Orientation.landscape;

  bool get isPortrait => orientation == Orientation.portrait;

  Size get size => _mediaQuery.size;

  double get width => size.width;

  double get height => size.height;

  /// Breakpoint sesuai dokumen teknis (360/600/840).
  AppBreakpoint get breakpoint => AppBreakpointResolver.fromWidth(width);

  /// Mobile (< 600px) — portrait maupun landscape ponsel.
  bool get isMobile => width < AppBreakpointResolver.tabletMin;

  /// Tablet mulai 600px (portrait & foldable) hingga layar besar.
  bool get isTablet => width >= AppBreakpointResolver.tabletMin;

  /// Tablet landscape / layar lebar (>= 840px).
  bool get isTabletLandscape =>
      width >= AppBreakpointResolver.tabletLandscapeMin;

  /// NavigationRail dipakai mulai 840px.
  bool get useRail => isTabletLandscape;

  bool get isDesktop => width >= 1200;

  // --- Alias kompatibilitas ---
  bool get isCompactWidth => width < AppBreakpointResolver.tabletMin;

  bool get isMediumWidth =>
      width >= AppBreakpointResolver.tabletMin &&
      width < AppBreakpointResolver.tabletLandscapeMin;

  bool get isWideWidth => width >= AppBreakpointResolver.tabletLandscapeMin;
}

class ResponsiveLayout {
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppBreakpointResolver.tabletMin;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Tablet landscape (>= 840px) — NavigationRail.
  static bool useRail(BuildContext context) {
    return MediaQuery.of(context).size.width >=
        AppBreakpointResolver.tabletLandscapeMin;
  }

  static AppBreakpoint breakpointOf(BuildContext context) {
    return AppBreakpointResolver.fromWidth(MediaQuery.of(context).size.width);
  }

  static ResponsiveCondition of(BuildContext context) {
    return ResponsiveCondition.of(context);
  }

  static double scale(
    BuildContext context, {
    double portrait = 1.0,
    double landscape = 0.92,
    double tablet = 0.96,
    double wide = 1.0,
    double desktop = 1.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return desktop;
    if (width >= AppBreakpointResolver.tabletLandscapeMin) return wide;
    if (width >= AppBreakpointResolver.tabletMin) return tablet;
    return isLandscape(context) ? landscape : portrait;
  }

  static double adaptiveValue(
    BuildContext context, {
    required double portrait,
    double? landscape,
    double? tablet,
    double? wide,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return desktop ?? wide ?? tablet ?? portrait;
    if (width >= AppBreakpointResolver.tabletLandscapeMin) {
      return wide ?? tablet ?? landscape ?? portrait;
    }
    if (width >= AppBreakpointResolver.tabletMin) {
      return tablet ?? landscape ?? portrait;
    }
    return isLandscape(context) ? (landscape ?? portrait) : portrait;
  }

  static double fontSize(
    BuildContext context,
    double portrait, {
    double? landscape,
    double? tablet,
    double? wide,
    double? desktop,
  }) {
    final fallbackLandscape = landscape ?? (portrait * 0.92);
    final fallbackTablet = tablet ?? portrait;
    final fallbackWide = wide ?? portrait;
    final fallbackDesktop = desktop ?? fallbackWide;
    return portrait *
        scale(
          context,
          portrait: 1.0,
          landscape: fallbackLandscape / portrait,
          tablet: fallbackTablet / portrait,
          wide: fallbackWide / portrait,
          desktop: fallbackDesktop / portrait,
        );
  }

  static double iconSize(
    BuildContext context,
    double portrait, {
    double? landscape,
    double? tablet,
    double? wide,
    double? desktop,
  }) {
    return fontSize(
      context,
      portrait,
      landscape: landscape,
      tablet: tablet,
      wide: wide,
      desktop: desktop,
    );
  }

  static double height(
    BuildContext context,
    double portrait, {
    double? landscape,
    double? tablet,
    double? wide,
    double? desktop,
  }) {
    return fontSize(
      context,
      portrait,
      landscape: landscape,
      tablet: tablet,
      wide: wide,
      desktop: desktop,
    );
  }

  static EdgeInsets contentPadding(
    BuildContext context, {
    double portraitHorizontal = 24,
    double portraitVertical = 24,
    double landscapeHorizontal = 24,
    double landscapeVertical = 18,
    double tabletHorizontal = 20,
    double tabletVertical = 16,
    double wideHorizontal = 24,
    double wideVertical = 18,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return EdgeInsets.symmetric(
        horizontal: wideHorizontal,
        vertical: wideVertical,
      );
    }
    if (width >= AppBreakpointResolver.tabletMin) {
      return EdgeInsets.symmetric(
        horizontal: tabletHorizontal,
        vertical: tabletVertical,
      );
    }
    return EdgeInsets.symmetric(
      horizontal: isLandscape(context)
          ? landscapeHorizontal
          : portraitHorizontal,
      vertical: isLandscape(context) ? landscapeVertical : portraitVertical,
    );
  }

  static EdgeInsets adaptiveInsets(
    BuildContext context, {
    required EdgeInsets portrait,
    EdgeInsets? landscape,
    EdgeInsets? tablet,
    EdgeInsets? wide,
    EdgeInsets? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return desktop ?? wide ?? tablet ?? portrait;
    if (width >= AppBreakpointResolver.tabletLandscapeMin) {
      return wide ?? tablet ?? landscape ?? portrait;
    }
    if (width >= AppBreakpointResolver.tabletMin) {
      return tablet ?? landscape ?? portrait;
    }
    return isLandscape(context) ? (landscape ?? portrait) : portrait;
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double portrait = 24,
    double tablet = 24,
    double landscape = 32,
    double vertical = 24,
    double landscapeVertical = 20,
    double tabletVertical = 24,
    double wide = 32,
    double wideVertical = 24,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return EdgeInsets.symmetric(horizontal: wide, vertical: wideVertical);
    }
    if (width >= AppBreakpointResolver.tabletMin) {
      return EdgeInsets.symmetric(horizontal: tablet, vertical: tabletVertical);
    }
    return EdgeInsets.symmetric(
      horizontal: isLandscape(context) ? landscape : portrait,
      vertical: isLandscape(context) ? landscapeVertical : vertical,
    );
  }

  static double contentMaxWidth(
    BuildContext context, {
    double maxWidth = 1200,
    double tabletMaxWidth = 960,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= AppBreakpointResolver.tabletMin && screenWidth < 1200) {
      return math.min(screenWidth, tabletMaxWidth);
    }
    return math.min(screenWidth, maxWidth);
  }

  static int gridColumns(
    BuildContext context, {
    int portrait = 2,
    int landscape = 3,
    int tablet = 3,
    int wide = 4,
    int desktop = 5,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return desktop;
    if (width >= AppBreakpointResolver.tabletLandscapeMin) return wide;
    if (width >= AppBreakpointResolver.tabletMin) return tablet;
    if (isLandscape(context)) return landscape;
    return portrait;
  }
}

extension ResponsiveLayoutContextX on BuildContext {
  bool get isLandscape => ResponsiveLayout.of(this).isLandscape;

  bool get isPortrait => ResponsiveLayout.of(this).isPortrait;
}
