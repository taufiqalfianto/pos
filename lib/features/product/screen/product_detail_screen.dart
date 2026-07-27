import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/modern_dialog.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/helper/currency_helper.dart';
import 'package:pos/core/helper/file_helper.dart';
import 'package:pos/features/product/cubit/product_cubit.dart';
import '../data/model/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.isTablet(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isLandscape: isLandscape),
          SliverToBoxAdapter(
            child: _buildDetailsContent(context, isLandscape: isLandscape),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/edit-product', extra: product),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text(
          'Edit Produk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 18 : 20),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, {required bool isLandscape}) {
    final isTablet = ResponsiveLayout.isTablet(context);
    return SliverAppBar(
      expandedHeight: isLandscape
          ? (isTablet ? 220 : 240)
          : (isTablet ? 300 : 350),
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.background,
      iconTheme: const IconThemeData(
        color: Colors.white,
      ), // Overriding for header
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (product.imagePath.isNotEmpty)
              Image.file(
                File(FileHelper.getFullPath(product.imagePath)),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      size: 100,
                      color: Colors.white24,
                    ),
                  );
                },
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  size: 100,
                  color: Colors.white24,
                ),
              ),
            // Bottom gradient overlay for legibility
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black38],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded),
          onPressed: () => _showDeleteDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDetailsContent(
    BuildContext context, {
    required bool isLandscape,
  }) {
    final isTablet = ResponsiveLayout.isTablet(context);
    return Container(
      padding: EdgeInsets.all(
        isLandscape ? (isTablet ? 22 : 24) : (isTablet ? 28 : 32),
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppStyles.titleStyle.copyWith(
                        fontSize: isLandscape
                            ? (isTablet ? 22 : 24)
                            : (isTablet ? 26 : 28),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Kategori: Umum', style: AppStyles.subtitleStyle),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(isTablet ? 14 : 16),
                decoration: AppStyles.glassDecoration(
                  borderRadius: isTablet ? 18 : 20,
                ),
                child: Text(
                  CurrencyHelper.formatIdr(product.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 24 : 32),
          _buildInfoRow(
            context,
            Icons.inventory_2_rounded,
            'Stok Tersedia',
            '${product.stock} Unit',
          ),
          SizedBox(height: isTablet ? 12 : 16),
          _buildInfoRow(
            context,
            product.isSynced == 1
                ? Icons.cloud_done_rounded
                : Icons.cloud_off_rounded,
            'Status Sinkronisasi',
            product.isSynced == 1 ? 'Sudah Tersinkron' : 'Belum Tersinkron',
            color: product.isSynced == 1
                ? AppColors.success
                : AppColors.warning,
          ),
          SizedBox(height: isTablet ? 24 : 32),
          const Text(
            'Deskripsi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            product.description.isEmpty
                ? 'Tidak ada deskripsi untuk produk ini.'
                : product.description,
            style: const TextStyle(
              height: 1.6,
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Inventaris',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 20),
            decoration: AppStyles.glassDecoration(
              borderRadius: isTablet ? 20 : 24,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stok Saat Ini', style: AppStyles.subtitleStyle),
                    Text(
                      '${product.stock} Unit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 16 : 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/stock-report', extra: product),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('LIHAT LAPORAN STOK'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 14 : 16,
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isTablet ? 14 : 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: isLandscape ? (isTablet ? 64 : 72) : (isTablet ? 88 : 100),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    final isTablet = ResponsiveLayout.isTablet(context);
    return Container(
      padding: EdgeInsets.all(isTablet ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 18 : 20),
        boxShadow: AppStyles.premiumShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 8 : 10),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? AppColors.primary,
              size: isTablet ? 22 : 24,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 11 : 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 15 : 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    ModernDialog.show(
      context: context,
      title: 'Hapus Produk',
      content: Text(
        'Apakah Anda yakin ingin menghapus "${product.name}"?',
        textAlign: TextAlign.center,
        style: AppStyles.subtitleStyle,
      ),
      confirmText: 'HAPUS',
      cancelText: 'BATAL',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline_rounded,
      onConfirm: () {
        context.read<ProductCubit>().deleteProduct(product.id);
        Navigator.pop(context);
        ToastHelper.showSuccess(context, 'Produk berhasil dihapus');
      },
    );
  }
}
