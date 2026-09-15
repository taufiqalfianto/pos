import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/widgets/main_shell.dart';

/// Regresi: tablet tidak lagi memakai NavigationRail/Drawer — semua ukuran
/// layar memakai BottomNavigationBar (termasuk tab "Menu").
void main() {
  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Dashboard')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/order',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Kasir')),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('tablet memakai BottomNavigationBar tanpa NavigationRail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(Drawer), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
  });

  testWidgets('mobile tetap memakai BottomNavigationBar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
