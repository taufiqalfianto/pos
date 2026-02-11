import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/modern_dialog.dart';
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildDetailsContent(context)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 350,
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

  Widget _buildDetailsContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
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
                      style: AppStyles.titleStyle.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text('Kategori: Umum', style: AppStyles.subtitleStyle),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppStyles.glassDecoration(borderRadius: 20),
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
          const SizedBox(height: 32),
          _buildInfoRow(
            Icons.inventory_2_rounded,
            'Stok Tersedia',
            '${product.stock} Unit',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            product.isSynced == 1
                ? Icons.cloud_done_rounded
                : Icons.cloud_off_rounded,
            'Status Sinkronisasi',
            product.isSynced == 1 ? 'Sudah Tersinkron' : 'Belum Tersinkron',
            color: product.isSynced == 1
                ? AppColors.success
                : AppColors.warning,
          ),
          const SizedBox(height: 32),
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
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.glassDecoration(borderRadius: 24),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/stock-report', extra: product),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('LIHAT LAPORAN STOK'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Spacing for FAB
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppStyles.premiumShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
