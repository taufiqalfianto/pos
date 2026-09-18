import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/helper/currency_helper.dart';
import 'package:pos/core/helper/file_helper.dart';
import 'package:pos/core/util/modern_dialog.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/app_app_bar.dart';
import 'package:pos/core/widgets/shimmer_loading.dart';
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
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;
    final useCompactFab = isLandscape && !isTablet;

    return BlocListener<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state is ProductSyncSuccess) {
          ToastHelper.showSuccess(
            context,
            'Backup berhasil pada ${_formatSyncDate(state.lastSyncAt)}',
          );
        }
        if (state is ProductSyncError) {
          ToastHelper.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppAppBar(title: const Text('Dashboard')),
        body: Column(
          children: [
            _buildHeaderSection(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Ukuran kartu (lebar & tinggi) dihitung dari area grid yang
                  // tersisa supaya proporsional di tablet portrait/lanskap.
                  final gridPadding = EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  );
                  final grid = ResponsiveLayout.productGridMetrics(
                    constraints.biggest,
                    padding: gridPadding,
                    spacing: 16.w,
                  );
                  return BlocBuilder<ProductCubit, ProductState>(
                    builder: (context, state) {
                      if (state is ProductLoading) {
                        return ProductGridShimmer(
                          crossAxisCount: grid.columns,
                          childAspectRatio: grid.aspectRatio,
                          padding: gridPadding,
                        );
                      }
                      final products = _productsFromState(state);
                      if (products != null) {
                        if (products.isEmpty) {
                          return Center(
                            child: _buildEmptyState(
                              _searchController.text.isNotEmpty,
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            await context.read<ProductCubit>().loadProducts();
                          },
                          color: AppColors.primary,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: gridPadding,
                            children: [
                              for (final entry in groupProductsByCategory(
                                products,
                              ).entries)
                                _buildCategorySection(
                                  entry.key,
                                  entry.value,
                                  grid,
                                ),
                            ],
                          ),
                        );
                      }
                      if (state is ProductError) {
                        return Center(child: Text(state.message));
                      }
                      return const SizedBox();
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: useCompactFab
            ? FloatingActionButton(
                onPressed: () => context.push('/add'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: const Icon(Icons.add_rounded),
              )
            : FloatingActionButton.extended(
                onPressed: () => context.push('/add'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                label: const Text(
                  'Tambah Produk',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.add_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;

    return Container(
      padding: EdgeInsets.all(isLandscape || isTablet ? 12.w : 20.w),
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
                style: AppStyles.subtitleStyle.copyWith(
                  fontSize: isLandscape && !isTablet
                      ? 10.sp
                      : isTablet
                      ? 14.sp
                      : 16.sp,
                ),
              );
            },
          ),

          SizedBox(height: 4.h),
          Text(
            'Kelola Stok Anda',
            style: AppStyles.titleStyle.copyWith(
              fontSize: isLandscape && !isTablet
                  ? 8.sp
                  : isTablet
                  ? 15.sp
                  : 16.sp,
            ),
          ),
          SizedBox(height: isLandscape || isTablet ? 10.h : 14.h),
          _buildSyncInfoSection(),
          SizedBox(height: isLandscape || isTablet ? 10.h : 14.h),
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
              contentPadding: ResponsiveLayout.contentPadding(
                context,
                portraitHorizontal: 20,
                portraitVertical: 16,
                landscapeHorizontal: 16,
                landscapeVertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncInfoSection() {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        final isSyncing = state is ProductSyncLoading;
        final lastSyncAt = _lastSyncAtFromState(state);
        final isLandscape = context.isLandscape;
        final isTablet = ResponsiveLayout.of(context).isTablet;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape && !isTablet ? 10.w : 14.w,
            vertical: isLandscape && !isTablet ? 8.h : 10.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            boxShadow: AppStyles.premiumShadow,
          ),
          child: Row(
            children: [
              Container(
                width: isLandscape && !isTablet ? 30.r : 36.r,
                height: isLandscape && !isTablet ? 30.r : 36.r,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.sync_rounded,
                  color: AppColors.primary,
                  size: isLandscape && !isTablet ? 18.r : 20.r,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup Data',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isLandscape && !isTablet ? 11.sp : 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      lastSyncAt == null
                          ? 'Belum pernah backup'
                          : 'Backup terakhir: ${_formatSyncDate(lastSyncAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isLandscape && !isTablet ? 9.sp : 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              FilledButton.icon(
                onPressed: isSyncing
                    ? null
                    : () => context.read<ProductCubit>().syncData(),
                icon: isSyncing
                    ? SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.cloud_sync_rounded, size: 18.r),
                label: Text(isSyncing ? 'Membackup' : 'Backup'),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(
                    fontSize: isLandscape && !isTablet ? 10.sp : 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                  minimumSize: Size(0, isLandscape && !isTablet ? 34.h : 38.h),
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<ProductModel>? _productsFromState(ProductState state) {
    return switch (state) {
      ProductLoaded(:final products) => products,
      ProductSyncLoading(:final products) => products,
      _ => null,
    };
  }

  DateTime? _lastSyncAtFromState(ProductState state) {
    return switch (state) {
      ProductLoaded(:final lastSyncAt) => lastSyncAt,
      ProductSyncLoading(:final lastSyncAt) => lastSyncAt,
      ProductSyncSuccess(:final lastSyncAt) => lastSyncAt,
      ProductSyncError(:final lastSyncAt) => lastSyncAt,
      _ => null,
    };
  }

  String _formatSyncDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id').format(dateTime.toLocal());
  }

  /// Satu kelompok kategori: header + grid produk kelompok tersebut.
  ///
  /// ponytail: grid `shrinkWrap` di dalam ListView membangun semua kartu
  /// seketika; ganti ke sliver (`CustomScrollView` + `SliverGrid`) kalau jumlah
  /// produk sudah ratusan.
  Widget _buildCategorySection(
    String category,
    List<ProductModel> products,
    ({int columns, double aspectRatio}) grid,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 4.h, bottom: 10.h),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.subtitleStyle.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppStyles.radiusInner.r),
                ),
                child: Text(
                  '${products.length}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid.columns,
            childAspectRatio: grid.aspectRatio,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) =>
              _PremiumProductCard(product: products[index]),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildEmptyState([bool isSearch = false]) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(
              isLandscape && !isTablet
                  ? 20.sp
                  : isTablet
                  ? 24.sp
                  : 32.sp,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppStyles.premiumShadow,
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.inventory_2_rounded,
              size: isLandscape && !isTablet
                  ? 44.r
                  : isTablet
                  ? 56.r
                  : 64.r,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: isLandscape || isTablet ? 14.h : 24.h),
          Text(
            isSearch ? 'Produk tidak ditemukan' : 'Belum ada produk',
            style: TextStyle(
              fontSize: isLandscape && !isTablet
                  ? 18.sp
                  : isTablet
                  ? 17.sp
                  : 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isLandscape || isTablet ? 6.h : 8.h),
          Text(
            isSearch
                ? 'Coba gunakan kata kunci pencarian yang lain'
                : 'Ketuk tombol + untuk mulai menambah produk',
            textAlign: TextAlign.center,
            style: isLandscape
                ? AppStyles.subtitleStyle.copyWith(
                    fontSize: isTablet ? 13.sp : 12.sp,
                  )
                : (isTablet
                      ? AppStyles.subtitleStyle.copyWith(fontSize: 13.sp)
                      : AppStyles.subtitleStyle),
          ),
          SizedBox(height: isLandscape || isTablet ? 14.h : 24.h),
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
        decoration: AppStyles.glassDecoration(borderRadius: 12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12.r),
                    ),
                    child: product.imagePath.isNotEmpty
                        ? Image.file(
                            File(FileHelper.getFullPath(product.imagePath)),
                            fit: BoxFit.cover,
                            cacheWidth: 350,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primary.withValues(
                                  alpha: 0.05,
                                ),
                                child: Icon(
                                  Icons.shopping_bag_rounded,
                                  size: 40.r,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.error.withValues(alpha: 0.05),
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              size: 40.r,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  // Positioned(
                  //   top: 8.h,
                  //   right: 8.w,
                  //   child: _buildPopOptions(context),
                  // ),
                  if (product.stock < 5)
                    Positioned(
                      bottom: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(
                            AppStyles.radiusInner.r,
                          ),
                        ),
                        child: Text(
                          'Stok Tipis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (product.stock <= 0)
                    Positioned(
                      bottom: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(
                            AppStyles.radiusInner.r,
                          ),
                        ),
                        child: Text(
                          'Stok Habis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    CurrencyHelper.formatIdr(product.price),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Modal: ${CurrencyHelper.formatIdr(product.costPrice)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        'Stok: ${product.stock}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: product.stock <= 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: product.stock <= 0
                              ? AppColors.error
                              : AppColors.textPrimary,
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
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert_rounded,
          size: 18.r,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusInner.r),
        ),
        onSelected: (value) {
          if (value == 'edit') {
            context.push('/edit-product', extra: product);
          } else if (value == 'delete') {
            _showDeleteDialog(context, product.id, product.name);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_rounded, size: 20.r),
              title: Text('Edit'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(
                Icons.delete_rounded,
                size: 20.r,
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

/// Kelompokkan produk dashboard per nama kategori, kunci terurut alfabetis
/// supaya urutan header stabil.
///
/// Kategori bawaan `general` bisa tak punya baris di tabel `categories`
/// (Join `getProducts` menghasilkan nama null) → dilabeli 'Umum'.
Map<String, List<ProductModel>> groupProductsByCategory(
  List<ProductModel> products,
) {
  final grouped = <String, List<ProductModel>>{};
  for (final product in products) {
    final name =
        product.categoryName ??
        (product.categoryId == 'general' ? 'Umum' : product.categoryId);
    grouped.putIfAbsent(name, () => <ProductModel>[]).add(product);
  }
  return Map.fromEntries(
    grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}
