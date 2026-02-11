import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/currency_helper.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/helper/file_helper.dart';
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
            final isWide = constraints.maxWidth > 900;
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              return Column(
                children: [
                  Expanded(child: _buildProductGrid(context, 2)),
                  Container(
                    height: 280.h,
                    child: _buildGlassCart(context, compact: true),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: isWide ? 3 : 2,
                  child: _buildProductGrid(context, isWide ? 5 : 3),
                ),
                if (isWide || constraints.maxWidth > 700)
                  const VerticalDivider(width: 1, color: Colors.black12),
                SizedBox(
                  width: isWide
                      ? 400.w
                      : (constraints.maxWidth > 700 ? 320.w : 0),
                  child: _buildGlassCart(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, int crossAxisCount) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            onChanged: (val) =>
                context.read<ProductCubit>().searchProducts(val),
            decoration: InputDecoration(
              hintText: 'Cari produk untuk order...',
              prefixIcon: const Icon(Icons.search_rounded),
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
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
    return Container(
      // margin: EdgeInsets.all(compact ? 10 : 20),
      decoration: AppStyles.glassDecoration(borderRadius: compact ? 12 : 32),
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
                  _buildEmptyCartPlaceholder(compact)
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        compact ? 16 : 24,
        compact ? 16 : 24,
        12,
      ),
      child: Row(
        children: [
          Text(
            'Keranjang',
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCartPlaceholder(bool compact) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: compact ? 32 : 48,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          SizedBox(height: compact ? 8 : 16),
          Text(
            compact ? 'Kosong' : 'Belum ada item',
            style: AppStyles.subtitleStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutFooter(BuildContext context, {bool compact = false}) {
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

        return Container(
          padding: EdgeInsets.all(compact ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(compact ? 24 : 32),
              bottomRight: Radius.circular(compact ? 24 : 32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    compact ? 'Total' : 'Total Pembayaran',
                    style: AppStyles.subtitleStyle,
                  ),
                  Text(
                    CurrencyHelper.formatIdr(total),
                    style: TextStyle(
                      fontSize: compact ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 16 : 24),
              SizedBox(
                width: double.infinity,
                height: compact ? 50 : 60,
                child: FilledButton(
                  onPressed: hasItems
                      ? () => context.read<OrderCubit>().checkout()
                      : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(compact ? 14 : 18),
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
  }

  void _showSuccessOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(color: AppColors.primary.withOpacity(0.95)),
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

    return GestureDetector(
      onTap: isOutOfStock
          ? null
          : () => context.read<OrderCubit>().addItem(product),
      child: Container(
        decoration: AppStyles.glassDecoration(
          borderRadius: 20.r,
          color: isOutOfStock ? Colors.grey[50] : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.03),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: product.imagePath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(FileHelper.getFullPath(product.imagePath)),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.shopping_bag_rounded,
                              size: 36,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          CurrencyHelper.formatIdr(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '(${product.stock})',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isOutOfStock
                              ? AppColors.error
                              : AppColors.textSecondary,
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
}

class _CartItemTile extends StatelessWidget {
  final dynamic item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyHelper.formatIdr(item.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildQtyBtn(
                Icons.remove_rounded,
                () => context.read<OrderCubit>().updateQuantity(
                  item.productId,
                  item.quantity - 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _buildQtyBtn(
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

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
