import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/features/auth/cubit/auth_cubit.dart';
import 'package:pos/features/auth/cubit/auth_state.dart';
import 'package:pos/features/auth/screen/login_screen.dart';
import 'package:pos/features/auth/screen/register_screen.dart';
import 'package:pos/features/auth/screen/change_password_screen.dart';
import 'package:pos/features/auth/screen/edit_profile_screen.dart';
import 'package:pos/features/auth/screen/splash_screen.dart';
import 'package:pos/features/product/data/model/product_model.dart';
import 'package:pos/features/product/screen/product_screen.dart';
import 'package:pos/features/product/screen/edit_product_screen.dart';
import 'package:pos/features/product/screen/product_detail_screen.dart';
import 'package:pos/features/product/screen/add_product_screen.dart';
import 'package:pos/features/product/screen/stock_report_screen.dart';
import 'package:pos/features/product/screen/add_stock_report_screen.dart';
import 'package:pos/features/product/screen/category_manage_screen.dart';
import 'package:pos/features/order/screen/order_screen.dart';
import 'package:pos/features/order/screen/order_history_screen.dart';
import 'package:pos/features/order/screen/sales_report_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final authState = authCubit.state;
        final bool loggingIn =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (authState is! Authenticated && state.matchedLocation != '/splash') {
          return loggingIn ? null : '/login';
        }

        if (authState is Authenticated && loggingIn) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const ProductListScreen(),
        ),
        GoRoute(
          path: '/order',
          builder: (context, state) => const OrderScreen(),
        ),
        GoRoute(
          path: '/order-history',
          builder: (context, state) => const OrderHistoryScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/add',
          builder: (context, state) => const AddProductScreen(),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: '/edit-product',
          builder: (context, state) {
            final product = state.extra as ProductModel;
            return EditProductScreen(product: product);
          },
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) {
            final product = state.extra as ProductModel;
            return ProductDetailScreen(product: product);
          },
        ),
        GoRoute(
          path: '/stock-report',
          builder: (context, state) {
            final product = state.extra as ProductModel;
            return StockReportScreen(product: product);
          },
        ),
        GoRoute(
          path: '/add-stock-report',
          builder: (context, state) {
            final product = state.extra as ProductModel;
            return AddStockReportScreen(product: product);
          },
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoryManageScreen(),
        ),
        GoRoute(
          path: '/sales-report',
          builder: (context, state) => const SalesReportScreen(),
        ),
      ],
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
