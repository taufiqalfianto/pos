import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/theme/app_theme.dart';
import 'package:pos/core/util/responsive_layout.dart';

void main() {
  Widget buildApp() {
    return ScreenUtilPlusInit(
      designSize: const Size(393, 852), // sama dengan lib/app.dart
      splitScreenMode: true,
      fontSizeResolver: (fontSize, instance) =>
          fontSize *
          AppBreakpointResolver.fontScaleFor(
            instance.screenWidth,
            instance.screenHeight,
          ),
      builder: (context, child) => MaterialApp(
        theme: AppTheme.lightTheme(context),
        home: const Scaffold(
          body: Center(child: FilledButton(onPressed: null, child: Text('OK'))),
        ),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildApp());
    // MaterialApp mengganti theme lewat AnimatedTheme (durasi 200ms);
    // tunggu hingga selesai agar Theme.of mengembalikan nilai akhir.
    await tester.pumpAndSettle();
  }

  TextTheme textThemeAt(WidgetTester tester) {
    final ctx = tester.element(find.byType(FilledButton));
    return Theme.of(ctx).textTheme;
  }

  testWidgets('theme tidak crash dan role font diskala per orientasi', (
    tester,
  ) async {
    // Portrait 393x852 → skala 1.0
    await pumpAt(tester, const Size(393, 852));
    expect(
      tester.takeException(),
      isNull,
      reason: 'portrait tidak boleh crash saat membangun theme',
    );
    var tt = textThemeAt(tester);
    expect(tt.labelLarge?.fontSize, 14.0);
    expect(tt.bodyMedium?.fontSize, 14.0);
    expect(tt.titleLarge?.fontSize, 20.0);

    // Landscape ponsel 667x375 → skala 0.9
    await pumpAt(tester, const Size(667, 375));
    expect(
      tester.takeException(),
      isNull,
      reason: 'landscape tidak boleh crash (regresi TextTheme.apply)',
    );
    tt = textThemeAt(tester);
    expect(tt.labelLarge?.fontSize, closeTo(12.6, 0.001));
    expect(tt.bodyMedium?.fontSize, closeTo(12.6, 0.001));
    expect(tt.titleLarge?.fontSize, closeTo(18.0, 0.001));

    // Tablet landscape 1024x768 → skala 0.95
    await pumpAt(tester, const Size(1024, 768));
    expect(tester.takeException(), isNull);
    tt = textThemeAt(tester);
    expect(tt.labelLarge?.fontSize, closeTo(13.3, 0.001));
  });
}
