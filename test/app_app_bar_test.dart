import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/theme/app_theme.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/app_app_bar.dart';

/// AppBar global harus primary + teks/ikon putih, baik lewat widget
/// `AppAppBar` maupun lewat `appBarTheme` (untuk AppBar/SliverAppBar apa pun).
void main() {
  testWidgets('AppAppBar memakai background primary dan kontras putih', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      LayoutBuilder(
        builder: (context, constraints) => ScreenUtilInit(
          designSize: AppBreakpointResolver.designSizeFor(constraints.biggest),
          splitScreenMode: true,
          fontSizeResolver: (fontSize, instance) =>
              AppBreakpointResolver.scaledFontSize(
                fontSize,
                instance.screenWidth,
                instance.screenHeight,
              ),
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme(context),
            home: Scaffold(
              appBar: AppAppBar(
                title: const Text('Kasir'),
                actions: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                ],
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(find.byType(AppAppBar));
    expect(appBar.backgroundColor, AppColors.primary);
    expect(appBar.foregroundColor, Colors.white);

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.appBarTheme.backgroundColor, AppColors.primary);
    expect(theme.appBarTheme.foregroundColor, Colors.white);
    expect(theme.appBarTheme.titleTextStyle?.color, Colors.white);
    expect(theme.appBarTheme.iconTheme?.color, Colors.white);
  });

  testWidgets('AppBar bawaan ikut primary lewat appBarTheme', (tester) async {
    await tester.pumpWidget(
      LayoutBuilder(
        builder: (context, constraints) => ScreenUtilInit(
          designSize: AppBreakpointResolver.designSizeFor(constraints.biggest),
          splitScreenMode: true,
          fontSizeResolver: (fontSize, instance) =>
              AppBreakpointResolver.scaledFontSize(
                fontSize,
                instance.screenWidth,
                instance.screenHeight,
              ),
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme(context),
            home: Scaffold(
              appBar: AppBar(title: const Text('Bawaan')),
              body: const SizedBox(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, isNull); // warna berasal dari tema
    final material = tester.widget<Material>(
      find
          .descendant(of: find.byType(AppBar), matching: find.byType(Material))
          .first,
    );
    expect(material.color, AppColors.primary);
  });
}
