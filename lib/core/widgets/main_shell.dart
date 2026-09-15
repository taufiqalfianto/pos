import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/features/auth/cubit/auth_cubit.dart';
import 'package:pos/features/auth/cubit/auth_state.dart';
import 'package:pos/features/order/cubit/sales_report_cubit.dart';

/// Shell navigasi: satu BottomNavigationBar untuk semua ukuran layar
/// (mobile & tablet), tanpa NavigationRail dan tanpa Drawer.
///
/// Menu yang dulu ada di Drawer (Manajemen Kategori, Edit Profil,
/// Ubah Password, Logout) dipindahkan ke tab "Menu" pada bottom navigation
/// bar agar tetap terjangkau dari tablet.
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _buildNavigationBar(context),
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
