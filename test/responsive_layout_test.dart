import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/util/responsive_layout.dart';

void main() {
  group('AppBreakpointResolver.fromWidth', () {
    test('Mobile Kecil (< 360px)', () {
      expect(AppBreakpointResolver.fromWidth(0), AppBreakpoint.mobileSmall);
      expect(AppBreakpointResolver.fromWidth(359), AppBreakpoint.mobileSmall);
    });

    test('Mobile / Mobile Landscape (360px - 599px)', () {
      expect(AppBreakpointResolver.fromWidth(360), AppBreakpoint.mobile);
      expect(AppBreakpointResolver.fromWidth(393), AppBreakpoint.mobile);
      expect(AppBreakpointResolver.fromWidth(599), AppBreakpoint.mobile);
    });

    test('Tablet Portrait & Foldable (600px - 839px)', () {
      expect(
        AppBreakpointResolver.fromWidth(600),
        AppBreakpoint.tabletPortrait,
      );
      expect(
        AppBreakpointResolver.fromWidth(800),
        AppBreakpoint.tabletPortrait,
      );
      expect(
        AppBreakpointResolver.fromWidth(839),
        AppBreakpoint.tabletPortrait,
      );
    });

    test('Tablet Landscape (>= 840px)', () {
      expect(
        AppBreakpointResolver.fromWidth(840),
        AppBreakpoint.tabletLandscape,
      );
      expect(
        AppBreakpointResolver.fromWidth(1180),
        AppBreakpoint.tabletLandscape,
      );
      expect(
        AppBreakpointResolver.fromWidth(2048),
        AppBreakpoint.tabletLandscape,
      );
    });
  });

  group('AppBreakpointResolver.fontScaleFor', () {
    test('Mobile portrait tetap 1.0', () {
      expect(AppBreakpointResolver.fontScaleFor(393, 852), 1.0);
      expect(AppBreakpointResolver.fontScaleFor(320, 568), 1.0);
      expect(AppBreakpointResolver.fontScaleFor(599, 700), 1.0);
    });

    test('Mobile landscape mengecil ke 0.9', () {
      expect(AppBreakpointResolver.fontScaleFor(599, 320), 0.9);
      // Landscape ponsel berlebar >= 600px tetap dianggap ponsel landscape.
      expect(AppBreakpointResolver.fontScaleFor(667, 375), 0.9);
      expect(AppBreakpointResolver.fontScaleFor(761, 390), 0.9);
    });

    test('Tablet font dibesarkan ke 1.1', () {
      expect(AppBreakpointResolver.fontScaleFor(600, 800), 1.1);
      expect(AppBreakpointResolver.fontScaleFor(768, 1024), 1.1);
      expect(AppBreakpointResolver.fontScaleFor(800, 1280), 1.1);
      expect(AppBreakpointResolver.fontScaleFor(840, 600), 1.1);
      expect(AppBreakpointResolver.fontScaleFor(1024, 768), 1.1);
      expect(AppBreakpointResolver.fontScaleFor(915, 412), 1.1);
    });

    test('Layar lebar / desktop 1.15', () {
      expect(AppBreakpointResolver.fontScaleFor(1200, 800), 1.15);
      expect(AppBreakpointResolver.fontScaleFor(1280, 800), 1.15);
      expect(AppBreakpointResolver.fontScaleFor(1366, 768), 1.15);
    });

    test('scaledFontSize mengalikan faktor breakpoint', () {
      expect(AppBreakpointResolver.scaledFontSize(12, 393, 852), 12);
      expect(
        AppBreakpointResolver.scaledFontSize(12, 1280, 800),
        closeTo(13.8, 0.001),
      );
    });
  });

  group('AppBreakpointResolver.designSizeFor', () {
    test('ponsel memakai ukuran desain asli', () {
      expect(
        AppBreakpointResolver.designSizeFor(const Size(393, 852)),
        AppBreakpointResolver.phoneDesignSize,
      );
      expect(
        AppBreakpointResolver.designSizeFor(const Size(412, 915)),
        AppBreakpointResolver.phoneDesignSize,
      );
    });

    test('tablet membatasi skala lebar ke maxWidthScale', () {
      for (final size in const [
        Size(744, 1133),
        Size(800, 1280),
        Size(1024, 768),
        Size(1280, 800),
        Size(1440, 900),
      ]) {
        final design = AppBreakpointResolver.designSizeFor(size);
        expect(size.width / design.width, lessThanOrEqualTo(1.5 + 1e-9));
        expect(size.height / design.height, lessThanOrEqualTo(1.5 + 1e-9));
      }
    });
  });
}
