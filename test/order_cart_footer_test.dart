import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/theme/app_theme.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/features/order/cubit/order_cubit.dart';
import 'package:pos/features/order/repository/order_repository.dart';
import 'package:pos/features/order/screen/order_screen.dart';
import 'package:pos/features/product/cubit/product_cubit.dart';
import 'package:pos/features/product/data/model/product_model.dart';
import 'package:pos/features/product/repository/product_repository.dart';

const _products = [
  ProductModel(
    id: '1',
    name: 'Kopi Susu',
    price: 25000,
    imagePath: '',
    stock: 9,
  ),
  ProductModel(
    id: '2',
    name: 'Teh Manis',
    price: 15000,
    imagePath: '',
    stock: 9,
  ),
  ProductModel(
    id: '3',
    name: 'Roti Bakar',
    price: 18000,
    imagePath: '',
    stock: 9,
  ),
  ProductModel(
    id: '4',
    name: 'Nasi Goreng',
    price: 22000,
    imagePath: '',
    stock: 9,
  ),
  ProductModel(
    id: '5',
    name: 'Es Jeruk',
    price: 12000,
    imagePath: '',
    stock: 9,
  ),
  ProductModel(
    id: '6',
    name: 'Pisang Goreng',
    price: 10000,
    imagePath: '',
    stock: 9,
  ),
];

class _FakeProductRepository extends ProductRepository {
  @override
  Stream<void> get productUpdates => const Stream<void>.empty();
  @override
  Future<List<ProductModel>> getProducts() async => _products;
}

class _FakeOrderRepository extends OrderRepository {}

/// Font bawaan flutter_test (Ahem) melebar sehingga memicu overflow palsu.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final loader = FontLoader('Roboto');
  for (final name in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
    final file = File('${dir.path}/$name');
    if (!file.existsSync()) continue;
    loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadRoboto);

  testWidgets('footer checkout tetap di bawah saat item bertambah & discroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = _FakeProductRepository();
    final productCubit = ProductCubit(repository);
    final orderCubit = OrderCubit(_FakeOrderRepository(), repository);

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
          builder: (context, _) {
            final theme = AppTheme.lightTheme(context);
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: productCubit),
                BlocProvider.value(value: orderCubit),
              ],
              child: MaterialApp(
                theme: theme.copyWith(
                  textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
                ),
                home: const OrderScreen(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final product in _products) {
      orderCubit.addItem(product);
    }
    await tester.pumpAndSettle();

    expect(find.text('BAYAR'), findsOneWidget);
    final footerBefore = tester.getTopLeft(find.text('Total'));

    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(
      listView.controller!.offset,
      greaterThan(0),
      reason: 'daftar item harus terscroll',
    );
    expect(
      tester.getTopLeft(find.text('Total')),
      footerBefore,
      reason: 'footer + tombol BAYAR tidak boleh ikut terscroll',
    );
    expect(find.text('BAYAR'), findsOneWidget);
  });
}
