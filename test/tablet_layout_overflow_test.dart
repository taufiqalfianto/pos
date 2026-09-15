import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/shimmer_loading.dart';

/// Regresi layout tablet: skeleton grid statistik tidak boleh RenderFlex
/// overflow lagi setelah navigasi jadi BottomNavigationBar di tablet.
/// Tablet portrait (1024x1366) paling rawan karena sel grid menyempit
/// sementara padding/ikon ikut skala lebar layar.
void main() {
  const tabletSizes = [
    Size(393, 852), // baseline mobile
    Size(600, 960),
    Size(800, 1280),
    Size(900, 1440),
    Size(1024, 768),
    Size(1024, 1366),
    Size(1280, 800),
    Size(1366, 1024),
  ];

  Widget wrap(Widget child) => LayoutBuilder(
    builder: (context, constraints) => ScreenUtilInit(
      designSize: AppBreakpointResolver.designSizeFor(constraints.biggest),
      splitScreenMode: true,
      fontSizeResolver: (fontSize, instance) =>
          AppBreakpointResolver.scaledFontSize(
            fontSize,
            instance.screenWidth,
            instance.screenHeight,
          ),
      builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
    ),
  );

  /// Kolom grid produk mengikuti ProductListScreen (portrait 2 / landscape 3 /
  /// wide 4 / desktop 5).
  Widget productGridShimmer() => Builder(
    builder: (context) => ProductGridShimmer(
      crossAxisCount: ResponsiveLayout.gridColumns(
        context,
        portrait: 2,
        landscape: 3,
        wide: 4,
        desktop: 5,
      ),
      childAspectRatio: 0.72,
    ),
  );

  Future<List<String>> overflowsOf(WidgetTester tester, Widget child) async {
    final captured = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) =>
        captured.add(details.exceptionAsString().split('\n').first);
    await tester.pumpWidget(wrap(child));
    await tester.pump(const Duration(milliseconds: 100));
    FlutterError.onError = previous;
    while (tester.takeException() != null) {}
    return captured;
  }

  for (final size in tabletSizes) {
    testWidgets('tidak ada overflow di ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final overflows = await overflowsOf(tester, productGridShimmer());
      overflows.addAll(await overflowsOf(tester, const SalesReportShimmer()));
      overflows.addAll(await overflowsOf(tester, const ListShimmer()));

      expect(overflows, isEmpty);
    });
  }
}
