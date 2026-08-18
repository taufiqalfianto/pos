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

    test('Tablet portrait tetap 1.0', () {
      expect(AppBreakpointResolver.fontScaleFor(600, 800), 1.0);
      expect(AppBreakpointResolver.fontScaleFor(768, 1024), 1.0);
      expect(AppBreakpointResolver.fontScaleFor(839, 1024), 1.0);
    });

    test('Tablet landscape / wide 0.95, desktop 1.0', () {
      expect(AppBreakpointResolver.fontScaleFor(840, 600), 0.95);
      expect(AppBreakpointResolver.fontScaleFor(1024, 768), 0.95);
      expect(AppBreakpointResolver.fontScaleFor(915, 412), 0.95);
      expect(AppBreakpointResolver.fontScaleFor(1200, 800), 1.0);
      expect(AppBreakpointResolver.fontScaleFor(1366, 768), 1.0);
    });
  });
}
