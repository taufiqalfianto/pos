import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/currency_helper.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/helper/file_helper.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/features/order/cubit/order_cubit.dart';
import 'package:pos/features/order/cubit/order_state.dart';
import 'package:pos/features/product/cubit/product_cubit.dart';
import 'package:pos/features/product/data/model/product_model.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ScrollController _cartScrollController = ScrollController();

  @override
  void dispose() {
    _cartScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Bersihkan Keranjang',
            onPressed: () => context.read<OrderCubit>().clearCart(),
          ),
        ],
      ),
      body: BlocListener<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderSuccess) {
            _showSuccessOverlay(context);
            context.read<ProductCubit>().loadProducts();
          } else if (state is OrderError) {
            ToastHelper.showError(context, state.message);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTabletWidth = constraints.maxWidth >= 700;

            if (!isTabletWidth) {
              return Column(
                children: [
                  Expanded(child: _buildProductGrid(context, 2)),
                  SizedBox(
                    height: 280.h,
                    child: _buildGlassCart(context, compact: true),
                  ),
                ],
              );
            }

            final productColumns = ResponsiveLayout.gridColumns(
              context,
              portrait: 2,
              landscape: 3,
              tablet: 3,
              wide: 4,
              desktop: 5,
            );

            return Row(
              children: [
                Expanded(child: _buildProductGrid(context, productColumns)),
                const VerticalDivider(width: 1, color: Colors.black12),
                Expanded(child: _buildGlassCart(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, int crossAxisCount) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isLandscape || isTablet ? 12 : 20),
          child: TextField(
            onChanged: (val) =>
                context.read<ProductCubit>().searchProducts(val),
            decoration: InputDecoration(
              hintText: 'Cari produk untuk order...',
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: ResponsiveLayout.contentPadding(
                context,
                portraitHorizontal: 20,
                portraitVertical: 14,
                landscapeHorizontal: 16,
                landscapeVertical: 8,
              ),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProductLoaded) {
                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    isLandscape || isTablet ? 12 : 20,
                    0,
                    isLandscape || isTablet ? 12 : 20,
                    isLandscape || isTablet ? 12 : 20,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: isLandscape && !isTablet
                        ? 1.6
                        : (isTablet ? 0.95 : 0.82),
                    crossAxisSpacing: isLandscape || isTablet ? 10 : 12,
                    mainAxisSpacing: isLandscape || isTablet ? 10 : 12,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    return _OrderProductItem(product: state.products[index]);
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCart(BuildContext context, {bool compact = false}) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;

    return Container(
      // margin: EdgeInsets.all(compact ? 10 : 20),
      decoration: AppStyles.glassDecoration(
        borderRadius: compact ? 12 : (isLandscape || isTablet ? 24 : 32),
      ),
      clipBehavior: Clip.antiAlias,
      child: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          final items = state is OrderCartUpdated
              ? state.items
              : (context.read<OrderCubit>().state is OrderCartUpdated
                    ? (context.read<OrderCubit>().state as OrderCartUpdated)
                          .items
                    : []);

          return Scrollbar(
            controller: _cartScrollController,
            thumbVisibility: true,
            thickness: 4,
            radius: const Radius.circular(8),
            child: ListView(
              controller: _cartScrollController,
              padding: EdgeInsets.zero,
              children: [
                _buildCartHeader(context, compact: compact),
                if (items.isEmpty)
                  _buildEmptyCartPlaceholder(context, compact)
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: _CartItemTile(item: item),
                    ),
                  ),
                _buildCheckoutFooter(context, compact: compact),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartHeader(BuildContext context, {bool compact = false}) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : (isLandscape || isTablet ? 18 : 24),
        compact ? 16 : (isLandscape || isTablet ? 18 : 24),
        compact ? 16 : (isLandscape || isTablet ? 18 : 24),
        isLandscape || isTablet ? 8 : 12,
      ),
      child: Row(
        children: [
          Text(
            'Keranjang',
            style: TextStyle(
              fontSize: compact ? 16 : (isLandscape || isTablet ? 16 : 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape || isTablet ? 8 : 10,
              vertical: isLandscape || isTablet ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: BlocBuilder<OrderCubit, OrderState>(
              builder: (context, state) {
                int count = 0;
                if (state is OrderCartUpdated) {
                  count = state.items.length;
                } else if (context.read<OrderCubit>().state
                    is OrderCartUpdated) {
                  count = (context.read<OrderCubit>().state as OrderCartUpdated)
                      .items
                      .length;
                }
                return Text(
                  '$count item',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCartPlaceholder(BuildContext context, bool compact) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;

    return SizedBox(
      height: compact
          ? (isLandscape || isTablet ? 108 : 132)
          : (isLandscape || isTablet ? 120 : 150),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: compact
                    ? (isLandscape || isTablet ? 28 : 32)
                    : (isLandscape || isTablet ? 36 : 48),
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              SizedBox(
                height: compact
                    ? (isLandscape || isTablet ? 6 : 8)
                    : (isLandscape || isTablet ? 8 : 16),
              ),
              Text(
                'Belum ada item',
                style: AppStyles.subtitleStyle.copyWith(
                  fontSize: isLandscape || isTablet ? 8.sp : 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutFooter(BuildContext context, {bool compact = false}) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;

    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        double total = 0.0;
        bool hasItems = false;

        if (state is OrderCartUpdated) {
          total = state.total;
          hasItems = state.items.isNotEmpty;
        } else if (context.read<OrderCubit>().state is OrderCartUpdated) {
          final s = context.read<OrderCubit>().state as OrderCartUpdated;
          total = s.total;
          hasItems = s.items.isNotEmpty;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 260;

            return Container(
              padding: EdgeInsets.all(
                compact ? 16 : (isLandscape || isTablet ? 18 : 24),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(compact ? 24 : 32),
                  bottomRight: Radius.circular(compact ? 24 : 32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isNarrow)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: AppStyles.subtitleStyle.copyWith(
                            fontSize: isLandscape || isTablet ? 8.sp : 12.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyHelper.formatIdr(total),
                            style: TextStyle(
                              fontSize: compact
                                  ? (isLandscape || isTablet ? 17 : 18)
                                  : (isLandscape || isTablet ? 18 : 20),
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total',
                            style: AppStyles.subtitleStyle.copyWith(
                              fontSize: isLandscape || isTablet ? 8.sp : 12.sp,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              CurrencyHelper.formatIdr(total),
                              style: TextStyle(
                                fontSize: compact
                                    ? (isLandscape || isTablet ? 17 : 18)
                                    : (isLandscape || isTablet ? 18 : 20),
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: compact ? 16 : 24),
                  SizedBox(
                    width: double.infinity,
                    height: compact ? 25 : (isLandscape || isTablet ? 45 : 40),
                    child: FilledButton(
                      onPressed: hasItems
                          ? () => context.read<OrderCubit>().checkout()
                          : null,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            compact ? 14 : 18,
                          ),
                        ),
                      ),
                      child: Text(
                        compact ? 'BAYAR' : 'BAYAR SEKARANG',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppColors.primary.withValues(alpha: 0.95),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'TRANSAKSI BERHASIL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'SELESAI',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderProductItem extends StatelessWidget {
  final ProductModel product;
  const _OrderProductItem({required this.product});

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;
    final useHorizontalLayout = isLandscape && !isTablet;

    return GestureDetector(
      onTap: isOutOfStock
          ? null
          : () => context.read<OrderCubit>().addItem(product),
      child: Container(
        decoration: AppStyles.glassDecoration(
          borderRadius: useHorizontalLayout ? 14 : (isTablet ? 16 : 20),
          color: isOutOfStock ? Colors.grey[100] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: useHorizontalLayout
            ? _buildHorizontalContent(context, isOutOfStock)
            : _buildVerticalContent(context, isOutOfStock, isTablet),
      ),
    );
  }

  Widget _buildHorizontalContent(BuildContext context, bool isOutOfStock) {
    return Row(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(14.r),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: product.imagePath.isNotEmpty
                        ? Image.file(
                            File(FileHelper.getFullPath(product.imagePath)),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.shopping_bag_rounded,
                                  size: 28,
                                  color: AppColors.primary,
                                ),
                          )
                        : const Icon(
                            Icons.shopping_bag_rounded,
                            size: 28,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                if (isOutOfStock)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Habis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  CurrencyHelper.formatIdr(product.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Stok: ${product.stock}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: isOutOfStock
                        ? AppColors.error
                        : AppColors.textSecondary,
                    fontWeight: isOutOfStock
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalContent(
    BuildContext context,
    bool isOutOfStock,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isTablet ? 6 : 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isTablet ? 16.r : 20.r),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: product.imagePath.isNotEmpty
                        ? Image.file(
                            File(FileHelper.getFullPath(product.imagePath)),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.shopping_bag_rounded,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                if (isOutOfStock)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Habis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(isTablet ? 8.w : 10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 12.sp : 13.sp,
                ),
              ),
              SizedBox(height: isTablet ? 2.h : 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      CurrencyHelper.formatIdr(product.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: isTablet ? 10.sp : 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '(${product.stock})',
                    style: TextStyle(
                      fontSize: isTablet ? 9.sp : 10.sp,
                      color: isOutOfStock
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight: isOutOfStock
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final dynamic item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;

    return Container(
      padding: EdgeInsets.all(isLandscape || isTablet ? 10.w : 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isLandscape || isTablet ? 12.sp : 13.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyHelper.formatIdr(item.price),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: isLandscape || isTablet ? 11.sp : 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildQtyBtn(
                context,
                Icons.remove_rounded,
                () => context.read<OrderCubit>().updateQuantity(
                  item.productId,
                  item.quantity - 1,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape || isTablet ? 8 : 12,
                ),
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isLandscape || isTablet ? 12.sp : 13.sp,
                  ),
                ),
              ),
              _buildQtyBtn(
                context,
                Icons.add_rounded,
                () => context.read<OrderCubit>().updateQuantity(
                  item.productId,
                  item.quantity + 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLandscape || isTablet ? 3 : 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: isLandscape || isTablet ? 18 : 20,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
