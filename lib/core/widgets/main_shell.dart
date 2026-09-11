import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/widgets/app_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/features/auth/cubit/auth_cubit.dart';
import 'package:pos/features/auth/cubit/auth_state.dart';
import 'package:pos/features/order/cubit/sales_report_cubit.dart';

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

  static const _ShellDestination _moreDestination = _ShellDestination(
    icon: Icons.grid_view_rounded,
    selectedIcon: Icons.grid_view_rounded,
    label: 'Menu',
  );

  void _onDestinationSelected(BuildContext context, int index) {
    if (index >= _destinations.length) {
      _showMoreMenu(context);
      return;
    }

    navigationShell.goBranch(
      index,
      // Saat menekan tab yang sedang aktif, kembali ke root branch-nya.
      initialLocation: index == navigationShell.currentIndex,
    );

    if (_destinations[index].label == 'Laporan') {
      context.read<SalesReportCubit>().refreshCurrentReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final useRail = ResponsiveLayout.of(context).useRail;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: useRail ? _buildRailLayout(context) : navigationShell,
      bottomNavigationBar: useRail ? null : _buildNavigationBar(context),
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
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            leading: Padding(
              padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
              child: AppLogo(size: extended ? 48.w : 40.w),
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
          VerticalDivider(width: 1.w, thickness: 1.w),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return NavigationBar(
      backgroundColor: Colors.white,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => _onDestinationSelected(context, index),
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      destinations: [
        for (final d in _destinations)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ),
        NavigationDestination(
          icon: Icon(_moreDestination.icon),
          selectedIcon: Icon(_moreDestination.selectedIcon),
          label: _moreDestination.label,
        ),
      ],
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Menu Lainnya',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12.h),
              _MoreMenuItem(
                icon: Icons.category_rounded,
                title: 'Manajemen Kategori',
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/categories');
                },
              ),
              _MoreMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profil',
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/edit-profile');
                },
              ),
              _MoreMenuItem(
                icon: Icons.lock_reset_rounded,
                title: 'Ubah Password',
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/change-password');
                },
              ),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return _MoreMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    color: AppColors.error,
                    isLoading: isLoading,
                    onTap: isLoading
                        ? () {}
                        : () {
                            Navigator.pop(sheetContext);
                            context.read<AuthCubit>().logout();
                          },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.icon,
    required this.label,
    IconData? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.textPrimary;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(color: itemColor, fontWeight: FontWeight.w600),
      ),
      trailing: isLoading
          ? SizedBox(
              width: 18.w,
              height: 18.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppColors.primary,
                ),
              ),
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
    );
  }
}
