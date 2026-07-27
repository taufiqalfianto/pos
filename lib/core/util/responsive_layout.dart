import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  bool get isCompactWidth => width < 600;

  bool get isMediumWidth => width >= 600 && width < 900;

  bool get isWideWidth => width >= 900;

  bool get isTablet => width >= 700 && width < 1200;

  bool get isDesktop => width >= 1200;
}

class ResponsiveLayout {
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 700 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
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
    if (width >= 900) return wide;
    if (width >= 700) return tablet;
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
    if (width >= 900) return wide ?? tablet ?? landscape ?? portrait;
    if (width >= 700) return tablet ?? landscape ?? portrait;
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

  static double radius(
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
    if (width >= 700) {
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
    if (width >= 900) return wide ?? tablet ?? landscape ?? portrait;
    if (width >= 700) return tablet ?? landscape ?? portrait;
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
    if (width >= 700) {
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
    if (screenWidth >= 700 && screenWidth < 1200) {
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
    if (width >= 900) return wide;
    if (width >= 700) return tablet;
    if (isLandscape(context)) return landscape;
    return portrait;
  }
}

extension ResponsiveLayoutContextX on BuildContext {
  bool get isLandscape => ResponsiveLayout.of(this).isLandscape;

  bool get isPortrait => ResponsiveLayout.of(this).isPortrait;
}
