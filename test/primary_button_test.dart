import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/theme/app_theme.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/primary_button.dart';

void main() {
  Widget wrap(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => ScreenUtilInit(
        designSize: AppBreakpointResolver.designSizeFor(constraints.biggest),
        splitScreenMode: true,
        fontSizeResolver: (fontSize, instance) =>
            AppBreakpointResolver.scaledFontSize(
              fontSize,
              instance.screenWidth,
              instance.screenHeight,
            ),
        builder: (context, _) => MaterialApp(
          theme: AppTheme.lightTheme(context),
          home: Scaffold(
            body: Center(child: SizedBox(width: 320, child: child)),
          ),
        ),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Size size, Widget child) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(child));
    await tester.pumpAndSettle();
  }

  testWidgets('PrimaryButton memakai tinggi kanonik per breakpoint', (
    tester,
  ) async {
    final button = PrimaryButton(label: 'SIMPAN', onPressed: () {});
    // Tinggi kanonik 60 (portrait) · 52 (lanskap ponsel, tablet, desktop),
    // dikalikan skala `.h` ScreenUtil seperti token lain.
    double canonical(double design) => ScreenUtil().setHeight(design);

    await pumpAt(tester, const Size(393, 852), button);
    expect(
      tester.getSize(find.byType(PrimaryButton)).height,
      closeTo(canonical(60), 0.01),
    );

    for (final size in const [
      Size(667, 375), // lanskap ponsel
      Size(1024, 768), // tablet lanskap
      Size(834, 1112), // tablet portrait
      Size(1440, 900), // desktop
    ]) {
      await pumpAt(tester, size, button);
      expect(
        tester.getSize(find.byType(PrimaryButton)).height,
        closeTo(canonical(52), 0.01),
        reason: 'CTA harus 52 design unit di $size',
      );
    }
  });

  testWidgets('radius tombol & kartu dari satu token, tipografi ikut tema', (
    tester,
  ) async {
    final button = PrimaryButton(label: 'SIMPAN', onPressed: () {});
    await pumpAt(tester, const Size(393, 852), button);

    final ctx = tester.element(find.byType(PrimaryButton));
    final theme = Theme.of(ctx);
    final expected = BorderRadius.circular(AppStyles.radiusCard.r);

    for (final style in [
      theme.filledButtonTheme.style,
      theme.outlinedButtonTheme.style,
      theme.textButtonTheme.style,
    ]) {
      final shape =
          style?.shape?.resolve(<WidgetState>{}) as RoundedRectangleBorder?;
      expect(shape?.borderRadius.resolve(TextDirection.ltr), expected);
    }

    final cardShape = theme.cardTheme.shape as RoundedRectangleBorder?;
    expect(
      cardShape?.borderRadius.resolve(TextDirection.ltr),
      expected,
      reason: 'radius kartu harus sama dengan radius tombol',
    );

    final labelStyle = tester.widget<Text>(find.text('SIMPAN')).style!;
    expect(labelStyle.fontWeight, FontWeight.bold);
    expect(labelStyle.letterSpacing, 1);
    expect(
      labelStyle.fontFamily,
      theme.textTheme.labelLarge!.fontFamily,
      reason: 'tipografi tombol harus ikut font theme, bukan style lepas',
    );
  });
}
