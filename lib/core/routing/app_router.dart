import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/helper/app_logger.dart';
import 'package:pos/features/auth/cubit/auth_cubit.dart';
import 'package:pos/features/auth/cubit/auth_state.dart';
import 'package:pos/features/auth/screen/login_screen.dart';
import 'package:pos/features/auth/screen/register_screen.dart';
import 'package:pos/features/auth/screen/change_password_screen.dart';
import 'package:pos/features/auth/screen/backup_restore_screen.dart';
import 'package:pos/features/auth/screen/edit_profile_screen.dart';
import 'package:pos/features/auth/screen/local_data_warning_screen.dart';
import 'package:pos/features/auth/screen/splash_screen.dart';
import 'package:pos/core/widgets/main_shell.dart';
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
      observers: [RouteLoggerObserver()],
      redirect: (context, state) {
        final authState = authCubit.state;
        final bool isPublicRoute =
            state.matchedLocation == '/splash' ||
            state.matchedLocation == '/local-data-warning' ||
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (authState is AuthLoading || authState is AuthInitial) {
          return null;
        }

        if (state.matchedLocation == '/local-data-warning') {
          return null;
        }

        if (authState is Authenticated && isPublicRoute) {
          return '/';
        }

        if (authState is Unauthenticated && !isPublicRoute) {
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/local-data-warning',
          builder: (context, state) => const LocalDataWarningScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const ProductListScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/order',
                  builder: (context, state) => const OrderScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/order-history',
                  builder: (context, state) => const OrderHistoryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/sales-report',
                  builder: (context, state) => const SalesReportScreen(),
                ),
              ],
            ),
          ],
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
          path: '/backup-restore',
          builder: (context, state) => const BackupRestoreScreen(),
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
      ],
    );
  }
}

class RouteLoggerObserver extends NavigatorObserver {
  static const _logTag = 'Navigation';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.info(
      'Route push: route=${_routeName(route)}, previous=${_routeName(previousRoute)}',
      tag: _logTag,
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.info(
      'Route pop: route=${_routeName(route)}, previous=${_routeName(previousRoute)}',
      tag: _logTag,
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLogger.info(
      'Route replace: new=${_routeName(newRoute)}, old=${_routeName(oldRoute)}',
      tag: _logTag,
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  String _routeName(Route<dynamic>? route) {
    if (route == null) return '-';
    return route.settings.name ?? route.settings.toString();
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
