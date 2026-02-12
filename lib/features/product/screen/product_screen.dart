import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/helper/currency_helper.dart';
import 'package:pos/core/helper/file_helper.dart';
import 'package:pos/core/util/modern_dialog.dart';
import 'package:pos/features/product/data/model/product_model.dart';
import '../cubit/product_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
              tooltip: 'Sync Data',
              onPressed: () {
                context.read<ProductCubit>().syncData();
                ToastHelper.showInfo(
                  context,
                  'Penyelarasan data sedang berjalan...',
                );
              },
            ),
          ),
        ],
      ),
      drawer: _buildPremiumDrawer(context),
      body: Column(
        children: [
          _buildHeaderSection(),
          Expanded(
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ProductLoaded) {
                  if (state.products.isEmpty) {
                    return Center(child: _buildEmptyState());
                  }
                  final screenWidth = MediaQuery.of(context).size.width;
                  final crossAxisCount = screenWidth > 900
                      ? 5
                      : (screenWidth > 600 ? 3 : 2);

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return _PremiumProductCard(product: product);
                    },
                  );
                } else if (state is ProductError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        label: const Text(
          'Tambah Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final name = state is Authenticated
                  ? state.user.name
                  : 'Pengguna';
              return Text(
                'Halo, Selamat Datang $name!',
                style: AppStyles.subtitleStyle,
              );
            },
          ),

          SizedBox(height: 4.h),
          Text('Kelola Stok Anda', style: AppStyles.titleStyle),
          SizedBox(height: 20.h),
          TextField(
            controller: _searchController,
            onChanged: (query) =>
                context.read<ProductCubit>().searchProducts(query),
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: AppStyles.premiumShadow,
          ),
          child: Icon(
            Icons.inventory_2_rounded,
            size: 64,
            color: AppColors.primary.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Belum ada produk',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Ketuk tombol + untuk mulai menambah produk',
          style: AppStyles.subtitleStyle,
        ),
      ],
    );
  }

  Widget _buildPremiumDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final user = state is Authenticated ? state.user : null;
              final String name = user?.name ?? 'User';
              final String username = user?.username != null
                  ? '@${user!.username}'
                  : '';
              final String imagePath = user?.imagePath ?? '';

              return Container(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: imagePath.isNotEmpty
                          ? FileImage(File(FileHelper.getFullPath(imagePath)))
                          : null,
                      child: imagePath.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      username,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _DrawerItem(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            onTap: () => Navigator.pop(context),
            isActive: true,
          ),
          _DrawerItem(
            icon: Icons.shopping_cart_rounded,
            title: 'Transaksi (Kasir)',
            accentColor: AppColors.success,
            onTap: () => {Navigator.pop(context), context.push('/order')},
          ),
          _DrawerItem(
            icon: Icons.receipt_long_rounded,
            title: 'Riwayat Transaksi',
            onTap: () => {
              Navigator.pop(context),
              context.push('/order-history'),
            },
          ),
          const Divider(indent: 24, endIndent: 24, height: 40),
          _DrawerItem(
            icon: Icons.category_rounded,
            title: 'Manajemen Kategori',
            onTap: () => {Navigator.pop(context), context.push('/categories')},
          ),
          _DrawerItem(
            icon: Icons.analytics_rounded,
            title: 'Laporan Penjualan',
            onTap: () => {
              Navigator.pop(context),
              context.push('/sales-report'),
            },
          ),
          const Divider(indent: 24, endIndent: 24, height: 40),
          _DrawerItem(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profil',
            onTap: () => {
              Navigator.pop(context),
              context.push('/edit-profile'),
            },
          ),
          _DrawerItem(
            icon: Icons.lock_reset_rounded,
            title: 'Ubah Password',
            onTap: () => {
              Navigator.pop(context),
              context.push('/change-password'),
            },
          ),
          const SizedBox(height: 20),
          _DrawerItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            color: AppColors.error,
            onTap: () => context.read<AuthCubit>().logout(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PremiumProductCard extends StatelessWidget {
  final ProductModel product;
  const _PremiumProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail', extra: product),
      child: Container(
        decoration: AppStyles.glassDecoration(borderRadius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: product.imagePath.isNotEmpty
                        ? Image.file(
                            File(FileHelper.getFullPath(product.imagePath)),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primary.withOpacity(0.05),
                                child: const Icon(
                                  Icons.shopping_bag_rounded,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.primary.withOpacity(0.05),
                            child: const Icon(
                              Icons.shopping_bag_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildPopOptions(context),
                  ),
                  if (product.stock < 5)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Stok Tipis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyHelper.formatIdr(product.price),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: product.isSynced == 1
                              ? AppColors.success.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.isSynced == 1
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_off_rounded,
                              size: 12,
                              color: product.isSynced == 1
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.isSynced == 1 ? 'Sinc' : 'Off',
                              style: TextStyle(
                                fontSize: 10,
                                color: product.isSynced == 1
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Stok: ${product.stock}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopOptions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (value) {
          if (value == 'edit') {
            context.push('/edit-product', extra: product);
          } else if (value == 'delete') {
            _showDeleteDialog(context, product.id, product.name);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_rounded, size: 20),
              title: Text('Edit'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(
                Icons.delete_rounded,
                size: 20,
                color: AppColors.error,
              ),
              title: Text('Hapus', style: TextStyle(color: AppColors.error)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String id, String name) {
    ModernDialog.show(
      context: context,
      title: 'Hapus Produk',
      content: Text(
        'Apakah Anda yakin ingin menghapus "$name"?',
        textAlign: TextAlign.center,
        style: AppStyles.subtitleStyle,
      ),
      confirmText: 'HAPUS',
      cancelText: 'BATAL',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline_rounded,
      onConfirm: () {
        context.read<ProductCubit>().deleteProduct(id);
        ToastHelper.showSuccess(context, 'Produk berhasil dihapus');
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;
  final Color? accentColor;
  final bool isActive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.accentColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isActive ? activeColor : (color ?? AppColors.textSecondary),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? activeColor : (color ?? AppColors.textPrimary),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isActive ? activeColor.withOpacity(0.1) : null,
      ),
    );
  }
}
