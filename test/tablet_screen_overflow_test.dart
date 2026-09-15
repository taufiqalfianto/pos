import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pos/core/theme/app_theme.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/features/auth/cubit/auth_cubit.dart';
import 'package:pos/features/auth/data/model/user_model.dart';
import 'package:pos/features/auth/repository/auth_repository.dart';
import 'package:pos/features/auth/screen/login_screen.dart';
import 'package:pos/features/auth/screen/register_screen.dart';
import 'package:pos/features/order/cubit/order_cubit.dart';
import 'package:pos/features/order/cubit/sales_report_cubit.dart';
import 'package:pos/features/order/data/model/order_model.dart';
import 'package:pos/features/order/repository/order_repository.dart';
import 'package:pos/features/order/screen/order_history_screen.dart';
import 'package:pos/features/order/screen/order_screen.dart';
import 'package:pos/features/order/screen/sales_report_screen.dart';
import 'package:pos/features/product/cubit/category_cubit.dart';
import 'package:pos/features/product/cubit/product_cubit.dart';
import 'package:pos/features/product/cubit/stock_report_cubit.dart';
import 'package:pos/features/product/data/model/category_model.dart';
import 'package:pos/features/product/data/model/product_model.dart';
import 'package:pos/features/product/data/model/stock_report_model.dart';
import 'package:pos/features/product/repository/category_repository.dart';
import 'package:pos/features/product/repository/product_repository.dart';
import 'package:pos/features/product/screen/add_product_screen.dart';
import 'package:pos/features/product/screen/add_stock_report_screen.dart';
import 'package:pos/features/product/screen/category_manage_screen.dart';
import 'package:pos/features/product/screen/edit_product_screen.dart';
import 'package:pos/features/product/screen/product_detail_screen.dart';
import 'package:pos/features/product/screen/product_screen.dart';
import 'package:pos/features/product/screen/stock_report_screen.dart';

/// Regresi layout lintas menu: tidak boleh ada RenderFlex overflow di tablet
/// (dan ponsel) setelah skala `.w` dibatasi `maxWidthScale` + font tablet 1.1.
///
/// Nama produk sengaja panjang supaya kasus terburuk ikut teruji.
const _sampleProduct = ProductModel(
  id: '1',
  name: 'Kopi Susu Gula Aren Spesial',
  price: 25000,
  costPrice: 12000,
  imagePath: '',
  stock: 12,
  categoryId: 'general',
);

const _products = [
  _sampleProduct,
  ProductModel(
    id: '2',
    name: 'Roti Bakar Coklat Keju',
    price: 18000,
    costPrice: 9000,
    imagePath: '',
    stock: 0,
    categoryId: 'general',
  ),
];

class _FakeProductRepository extends ProductRepository {
  final _controller = StreamController<void>.broadcast();
  @override
  Stream<void> get productUpdates => _controller.stream;
  @override
  Future<List<ProductModel>> getProducts() async => _products;
  @override
  Future<List<StockReportModel>> getStockReports(String productId) async => [
    StockReportModel(
      id: 'r1',
      productId: productId,
      productName: _sampleProduct.name,
      systemStock: 10,
      manualStock: 12,
      adjustment: 2,
      note: 'Stok opname',
      createdAt: DateTime(2026, 9, 15),
    ),
  ];
  @override
  Future<void> syncPendingData() async {}
}

class _FakeOrderRepository extends OrderRepository {
  @override
  Future<List<OrderModel>> getOrders() async => [
    OrderModel(
      id: 'a1b2c3d4-1111-2222-3333-444455556666',
      items: const [
        OrderItemModel(
          productId: '1',
          productName: 'Kopi Susu Gula Aren Spesial',
          price: 25000,
          quantity: 2,
        ),
      ],
      totalPrice: 50000,
      createdAt: DateTime(2026, 9, 15, 10, 30),
      day: 15,
      month: 9,
      year: 2026,
    ),
  ];

  @override
  Future<Map<String, dynamic>> getSalesReport({
    int? day,
    int? month,
    int? year,
    String period = 'daily',
  }) async => {
    'total_orders': 3,
    'total_revenue': 150000.0,
    'total_cost': 70000.0,
    'total_profit': 80000.0,
    'category_sales': [
      {
        'category_name': 'Minuman',
        'revenue': 100000.0,
        'cost': 50000.0,
        'profit': 50000.0,
      },
    ],
    'payment_sales': [
      {'payment_method': 'cash', 'count': 2, 'revenue': 90000.0},
      {'payment_method': 'qris', 'count': 1, 'revenue': 60000.0},
    ],
  };
}

class _FakeCategoryRepository extends CategoryRepository {
  @override
  Future<List<CategoryModel>> getCategories() async => const [
    CategoryModel(id: 'general', name: 'Umum'),
    CategoryModel(id: 'minuman', name: 'Minuman'),
  ];
}

class _FakeAuthRepository extends AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;
}

/// Font bawaan flutter_test (Ahem) membuat lebar teks tidak realistis
/// (tiap glyph 1em) sehingga deteksi overflow palsu; muat Roboto bila ada.
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

  setUpAll(() async {
    await _loadRoboto();
    await initializeDateFormatting('id');
  });

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
      builder: (context, _) {
        final productRepository = _FakeProductRepository();
        final theme = AppTheme.lightTheme(context);
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ProductCubit(productRepository)),
            BlocProvider(create: (_) => StockReportCubit(productRepository)),
            BlocProvider(
              create: (_) =>
                  OrderCubit(_FakeOrderRepository(), productRepository),
            ),
            BlocProvider(
              create: (_) => CategoryCubit(_FakeCategoryRepository()),
            ),
            BlocProvider(
              create: (_) => SalesReportCubit(_FakeOrderRepository()),
            ),
            BlocProvider(create: (_) => AuthCubit(_FakeAuthRepository())),
          ],
          child: MaterialApp(
            theme: theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
            ),
            home: child,
          ),
        );
      },
      child: child,
    ),
  );

  final screens = <String, Widget Function()>{
    'Kasir': OrderScreen.new,
    'Dashboard': ProductListScreen.new,
    'Riwayat': OrderHistoryScreen.new,
    'Laporan': SalesReportScreen.new,
    'Tambah Produk': AddProductScreen.new,
    'Edit Produk': () => const EditProductScreen(product: _sampleProduct),
    'Detail Produk': () => const ProductDetailScreen(product: _sampleProduct),
    'Kategori': CategoryManageScreen.new,
    'Laporan Stok': () => const StockReportScreen(product: _sampleProduct),
    'Tambah Laporan Stok': () =>
        const AddStockReportScreen(product: _sampleProduct),
    'Login': LoginScreen.new,
    'Register': RegisterScreen.new,
  };

  const sizes = [
    Size(393, 852), // ponsel portrait (baseline, skala tidak boleh berubah)
    Size(744, 1133), // tablet portrait
    Size(800, 1280), // tablet portrait besar
    Size(1024, 768), // tablet landscape
    Size(1100, 700), // tablet landscape pendek
    Size(1280, 800), // tablet landscape umum
    Size(1366, 1024),
    Size(1440, 900),
  ];

  for (final entry in screens.entries) {
    testWidgets('${entry.key} tanpa overflow di semua ukuran', (tester) async {
      final failures = <String>[];

      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final captured = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) =>
            captured.add(details.toString().split('\n').first);
        await tester.pumpWidget(wrap(entry.value()));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));
        FlutterError.onError = previous;
        while (tester.takeException() != null) {}

        for (final error in captured) {
          failures.add('${size.width.toInt()}x${size.height.toInt()}: $error');
        }
      }

      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }
}
