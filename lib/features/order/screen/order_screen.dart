import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/currency_helper.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/helper/file_helper.dart';
import 'package:pos/core/helper/payment_method_helper.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/app_app_bar.dart';
import 'package:pos/core/widgets/loading_button_child.dart';
import 'package:pos/core/widgets/shimmer_loading.dart';
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
      appBar: AppAppBar(
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
            final isTabletWidth = constraints.maxWidth >= 600;

            if (!isTabletWidth) {
              return Column(
                children: [
                  Expanded(child: _buildProductGrid(context)),
                  SizedBox(
                    // Tinggi cart adaptif: hindari overflow di layar pendek
                    // (landscape) maupun saat keyboard terbuka.
                    height: math.min(280.h, constraints.maxHeight * 0.45),
                    child: _buildGlassCart(context, compact: true),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: _buildProductGrid(context)),
                VerticalDivider(width: 1.w, color: Colors.black12),
                Expanded(child: _buildGlassCart(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.of(context).isTablet;
    final useHorizontalItem = isLandscape && !isTablet;
    final gridPadding = EdgeInsets.fromLTRB(
      isLandscape || isTablet ? 12.w : 20.w,
      0,
      isLandscape || isTablet ? 12.w : 20.w,
      isLandscape || isTablet ? 12.h : 20.h,
    );
    final gridSpacing = isLandscape || isTablet ? 10.w : 12.w;
    final mainSpacing = isLandscape || isTablet ? 10.h : 12.h;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isLandscape || isTablet ? 12.w : 20.w),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Lebar & tinggi kartu mengikuti area grid + orientasi layar.
              final grid = ResponsiveLayout.productGridMetrics(
                constraints.biggest,
                padding: gridPadding,
                spacing: gridSpacing,
                minTileHeight: useHorizontalItem ? 110 : 150,
              );
              return BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading) {
                    return ProductGridShimmer(
                      crossAxisCount: grid.columns,
                      childAspectRatio: grid.aspectRatio,
                      padding: gridPadding,
                      crossAxisSpacing: gridSpacing,
                      mainAxisSpacing: mainSpacing,
                    );
                  }
                  if (state is ProductLoaded) {
                    return GridView.builder(
                      padding: gridPadding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: grid.columns,
                        childAspectRatio: grid.aspectRatio,
                        crossAxisSpacing: gridSpacing,
                        mainAxisSpacing: mainSpacing,
                      ),
                      itemCount: state.products.length,
                      itemBuilder: (context, index) {
                        return _OrderProductItem(
                          product: state.products[index],
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              );
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
      decoration: AppStyles.glassDecoration(
        borderRadius: compact ? 12 : (isLandscape || isTablet ? 24 : 32),
      ),
      clipBehavior: Clip.antiAlias,
      child: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          final orderCubit = context.read<OrderCubit>();
          final items = state is OrderCartUpdated
              ? state.items
              : orderCubit.cartItems;

          return Scrollbar(
            controller: _cartScrollController,
            thumbVisibility: true,
            thickness: 4.w,
            radius: Radius.circular(8.r),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
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
        compact ? 16.w : (isLandscape || isTablet ? 18.w : 24.w),
        compact ? 16.h : (isLandscape || isTablet ? 18.h : 24.h),
        compact ? 16.w : (isLandscape || isTablet ? 18.w : 24.w),
        isLandscape || isTablet ? 8.h : 12.h,
      ),
      child: Row(
        children: [
          Text(
            'Keranjang',
            style: TextStyle(
              fontSize: compact
                  ? 16.sp
                  : (isLandscape || isTablet ? 16.sp : 18.sp),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape || isTablet ? 8.w : 10.w,
              vertical: isLandscape || isTablet ? 3.h : 4.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: BlocBuilder<OrderCubit, OrderState>(
              builder: (context, state) {
                int count = context.read<OrderCubit>().cartItems.length;
                if (state is OrderCartUpdated) {
                  count = state.items.length;
                }
                return Text(
                  '$count item',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.sp,
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
          ? (isLandscape || isTablet ? 108.h : 132.h)
          : (isLandscape || isTablet ? 120.h : 150.h),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: compact
                    ? (isLandscape || isTablet ? 28.r : 32.r)
                    : (isLandscape || isTablet ? 36.r : 48.r),
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              SizedBox(
                height: compact
                    ? (isLandscape || isTablet ? 6.h : 8.h)
                    : (isLandscape || isTablet ? 8.h : 16.h),
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
        final orderCubit = context.read<OrderCubit>();
        double total = orderCubit.cartTotal;
        bool hasItems = orderCubit.cartItems.isNotEmpty;
        final isCheckingOut = state is OrderLoading && hasItems;

        if (state is OrderCartUpdated) {
          total = state.total;
          hasItems = state.items.isNotEmpty;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 260;

            return Container(
              padding: EdgeInsets.all(
                compact ? 16.w : (isLandscape || isTablet ? 18.w : 24.w),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(compact ? 24.r : 32.r),
                  bottomRight: Radius.circular(compact ? 24.r : 32.r),
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
                                  ? (isLandscape || isTablet ? 17.sp : 18.sp)
                                  : (isLandscape || isTablet ? 18.sp : 20.sp),
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
                              fontSize: isLandscape || isTablet ? 16.sp : 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              CurrencyHelper.formatIdr(total),
                              style: TextStyle(
                                fontSize: compact
                                    ? (isLandscape || isTablet ? 17.sp : 18.sp)
                                    : (isLandscape || isTablet ? 18.sp : 20.sp),
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: compact ? 16.h : 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: compact
                        ? 45.h
                        : (isLandscape || isTablet ? 45.h : 40.h),
                    child: FilledButton(
                      onPressed: hasItems && !isCheckingOut
                          ? () => _showPaymentPreviewDialog(context)
                          : null,
                      child: LoadingButtonChild(
                        isLoading: isCheckingOut,
                        label: compact ? 'BAYAR' : 'BAYAR SEKARANG',
                        textStyle: const TextStyle(
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
                    width: 100.w,
                    height: 100.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 64.r,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'TRANSAKSI BERHASIL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 40.h),
                  SizedBox(
                    width: 200.w,
                    height: ResponsiveLayout.adaptiveValue(
                      context,
                      portrait: 50,
                      landscape: 44,
                      tablet: 44,
                    ).h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white, width: 2.w),
                        foregroundColor: Colors.white,
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

  Future<void> _showPaymentPreviewDialog(BuildContext context) async {
    final orderCubit = context.read<OrderCubit>();
    final items = orderCubit.cartItems;
    if (items.isEmpty) return;

    final now = DateTime.now();
    final total = orderCubit.cartTotal;
    final totalQuantity = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    var selectedPaymentMethod = PaymentMethodHelper.cash;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusCard.r),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppStyles.radiusInner.r,
                      ),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Preview Pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PaymentPreviewRow(
                      label: 'Tanggal',
                      value: DateFormat('dd MMMM yyyy', 'id').format(now),
                    ),
                    SizedBox(height: 10.h),
                    _PaymentPreviewRow(
                      label: 'Waktu',
                      value: DateFormat('HH:mm:ss').format(now),
                    ),
                    SizedBox(height: 10.h),
                    _PaymentPreviewRow(
                      label: 'Jenis produk',
                      value: '${items.length} item',
                    ),
                    SizedBox(height: 10.h),
                    _PaymentPreviewRow(
                      label: 'Jumlah barang',
                      value: '$totalQuantity pcs',
                    ),
                    Divider(height: 28.h),
                    ...items.map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} x${item.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              CurrencyHelper.formatIdr(item.subtotal),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 28.h),
                    _PaymentPreviewRow(
                      label: 'Total bayar',
                      value: CurrencyHelper.formatIdr(total),
                      valueColor: AppColors.primary,
                      isEmphasis: true,
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: PaymentMethodHelper.cash,
                          label: Text('Cash'),
                          icon: Icon(Icons.payments_rounded),
                        ),
                        ButtonSegment(
                          value: PaymentMethodHelper.qris,
                          label: Text('QRIS'),
                          icon: Icon(Icons.qr_code_2_rounded),
                        ),
                      ],
                      selected: {selectedPaymentMethod},
                      onSelectionChanged: (selection) {
                        setDialogState(
                          () => selectedPaymentMethod = selection.first,
                        );
                      },
                    ),
                  ],
                ),
              ),
              actionsPadding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('BATAL'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    orderCubit.checkout(paymentMethod: selectedPaymentMethod);
                  },
                  child: const Text(
                    'KONFIRMASI',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PaymentPreviewRow extends StatelessWidget {
  const _PaymentPreviewRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isEmphasis ? 14.sp : 13.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: isEmphasis ? FontWeight.bold : FontWeight.w700,
              fontSize: isEmphasis ? 18.sp : 13.sp,
            ),
          ),
        ),
      ],
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
            padding: EdgeInsets.all(6.w),
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
                            cacheWidth: 350,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.shopping_bag_rounded,
                              size: 28.r,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(
                            Icons.shopping_bag_rounded,
                            size: 28.r,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                if (isOutOfStock)
                  Positioned(
                    top: 2.h,
                    left: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Habis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
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
            padding: EdgeInsets.all(isTablet ? 6.w : 8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppStyles.radiusCard.r),
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
                            cacheWidth: 350,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.shopping_bag_rounded,
                              size: 32.r,
                              color: AppColors.primary,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              size: 32.r,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                if (isOutOfStock)
                  Positioned(
                    top: 6.h,
                    right: 6.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Habis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
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
        borderRadius: BorderRadius.circular(AppStyles.radiusCard.r),
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
                    fontSize: isLandscape || isTablet ? 16.sp : 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyHelper.formatIdr(item.price),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: isLandscape || isTablet ? 16.sp : 14.sp,
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
                  horizontal: isLandscape || isTablet ? 8.w : 12.w,
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
        padding: EdgeInsets.all(isLandscape || isTablet ? 3.w : 4.w),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          size: isLandscape || isTablet ? 18.r : 20.r,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
