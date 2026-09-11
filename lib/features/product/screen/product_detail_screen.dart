import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          borderRadius: BorderRadius.circular(isTablet ? 18.r : 20.r),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, {required bool isLandscape}) {
    final isTablet = ResponsiveLayout.isTablet(context);
    return SliverAppBar(
      expandedHeight: isLandscape
          ? (isTablet ? 220.h : 240.h)
          : (isTablet ? 300.h : 350.h),
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
                      gradient: AppColors.brandGradient,
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      size: 100.r,
                      color: Colors.white24,
                    ),
                  );
                },
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                ),
                child: Icon(
                  Icons.shopping_bag_rounded,
                  size: 100.r,
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
        SizedBox(width: 8.w),
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
        isLandscape ? (isTablet ? 22.w : 24.w) : (isTablet ? 28.w : 32.w),
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
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
                            ? (isTablet ? 22.sp : 24.sp)
                            : (isTablet ? 26.sp : 28.sp),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text('Kategori: Umum', style: AppStyles.subtitleStyle),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(isTablet ? 14.w : 16.w),
                decoration: AppStyles.glassDecoration(
                  borderRadius: isTablet ? 18 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Harga Jual', style: AppStyles.subtitleStyle),
                    Text(
                      CurrencyHelper.formatIdr(product.price),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 20.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 24.h : 32.h),
          _buildInfoRow(
            context,
            Icons.inventory_2_rounded,
            'Stok Tersedia',
            '${product.stock} Unit',
          ),
          SizedBox(height: isTablet ? 12.h : 16.h),
          _buildInfoRow(
            context,
            Icons.savings_rounded,
            'Modal per Item',
            CurrencyHelper.formatIdr(product.costPrice),
            color: AppColors.tertiary,
          ),
          SizedBox(height: isTablet ? 12.h : 16.h),
          _buildInfoRow(
            context,
            Icons.account_balance_wallet_rounded,
            'Total Modal Stok',
            CurrencyHelper.formatIdr(product.costPrice * product.stock),
            color: AppColors.secondary,
          ),
          SizedBox(height: isTablet ? 12.h : 16.h),
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
          SizedBox(height: isTablet ? 24.h : 32.h),
          Text(
            'Deskripsi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            product.description.isEmpty
                ? 'Tidak ada deskripsi untuk produk ini.'
                : product.description,
            style: TextStyle(
              height: 1.6,
              color: AppColors.textSecondary,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Inventaris',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(isTablet ? 16.w : 20.w),
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
                SizedBox(height: isTablet ? 16.h : 20.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/stock-report', extra: product),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('LIHAT LAPORAN STOK'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 14.h : 16.h,
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isTablet ? 14.r : 16.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: isLandscape
                ? (isTablet ? 64.h : 72.h)
                : (isTablet ? 88.h : 100.h),
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
      padding: EdgeInsets.all(isTablet ? 14.w : 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 18.r : 20.r),
        boxShadow: AppStyles.premiumShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 8.w : 10.w),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? AppColors.primary,
              size: isTablet ? 22.r : 24.r,
            ),
          ),
          SizedBox(width: isTablet ? 12.w : 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 11.sp : 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 15.sp : 16.sp,
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
