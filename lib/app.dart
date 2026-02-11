import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/routing/app_router.dart';
import 'package:pos/core/theme/app_theme.dart';
import 'package:pos/features/auth/cubit/auth_cubit.dart';
import 'package:pos/features/product/cubit/product_cubit.dart';
import 'package:pos/features/product/repository/product_repository.dart';
import 'package:pos/features/order/cubit/order_cubit.dart';
import 'package:pos/features/order/repository/order_repository.dart';
import 'package:pos/features/product/cubit/stock_report_cubit.dart';
import 'package:pos/features/product/repository/category_repository.dart';
import 'package:pos/features/product/cubit/category_cubit.dart';
import 'package:pos/features/order/cubit/sales_report_cubit.dart';
import 'package:go_router/go_router.dart';

class PosApp extends StatefulWidget {
  final AuthCubit authCubit;
  const PosApp({super.key, required this.authCubit});

  @override
  State<PosApp> createState() => _PosAppState();
}

class _PosAppState extends State<PosApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(widget.authCubit);
  }

  @override
  Widget build(BuildContext context) {
    final productRepository = ProductRepository();
    final orderRepository = OrderRepository();

    return ScreenUtilInit(
      designSize: const Size(393, 852), // iPhone 14/15 base size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: widget.authCubit..checkAuth()),
            BlocProvider(create: (context) => ProductCubit(productRepository)),
            BlocProvider(
              create: (context) => StockReportCubit(productRepository),
            ),
            BlocProvider(
              create: (context) =>
                  OrderCubit(orderRepository, productRepository),
            ),
            BlocProvider(
              create: (context) => CategoryCubit(CategoryRepository()),
            ),
            BlocProvider(
              create: (context) => SalesReportCubit(orderRepository),
            ),
          ],
          child: MaterialApp.router(
            title: 'Flutter POS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: _router,
          ),
        );
      },
    );
  }
}
