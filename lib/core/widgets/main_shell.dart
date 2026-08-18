import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';

/// Shell navigasi adaptif (AC: Navigasi Adaptif).
///
/// - Lebar < 840px (mobile & tablet portrait): BottomNavigationBar.
/// - Lebar >= 840px (tablet landscape): NavigationRail di sisi kiri,
///   sehingga layar lebar dimanfaatkan secara optimal.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_ShellDestination> _destinations = [
    _ShellDestination(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _ShellDestination(icon: Icons.point_of_sale_rounded, label: 'Kasir'),
    _ShellDestination(icon: Icons.receipt_long_rounded, label: 'Riwayat'),
    _ShellDestination(icon: Icons.analytics_rounded, label: 'Laporan'),
  ];

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Saat menekan tab yang sedang aktif, kembali ke root branch-nya.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final useRail = ResponsiveLayout.of(context).useRail;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: useRail ? _buildRailLayout(context) : navigationShell,
      bottomNavigationBar: useRail ? null : _buildNavigationBar(),
    );
  }

  Widget _buildRailLayout(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 1000;

    return SafeArea(
      // Hanya amankan sisi kiri (notch pada landscape); status bar & home
      // indicator sudah ditangani AppBar screen & Scaffold.
      left: true,
      top: false,
      right: false,
      bottom: false,
      child: Row(
        children: [
          NavigationRail(
            extended: extended,
            backgroundColor: Colors.white,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            leading: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Icon(
                Icons.shopping_cart_checkout_rounded,
                color: AppColors.primary,
                size: extended ? 28 : 24,
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      backgroundColor: Colors.white,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _onDestinationSelected,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      destinations: [
        for (final d in _destinations)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ),
      ],
    );
  }
}

class _ShellDestination {
  const _ShellDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;

  IconData get selectedIcon => icon;
}
