import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/currency_helper.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/features/order/cubit/order_cubit.dart';
import 'package:pos/features/order/cubit/order_state.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<OrderCubit>().fetchOrderHistory();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderHistoryLoaded) {
            if (state.orders.isEmpty) {
              return _buildEmptyHistory();
            }

            return LayoutBuilder(
              builder: (context, _) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveLayout.contentMaxWidth(
                        context,
                        maxWidth: 840,
                      ),
                    ),
                    child: ListView.builder(
                      padding: ResponsiveLayout.pagePadding(context),
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) {
                        final order = state.orders[index];
                        return _PremiumHistoryCard(order: order);
                      },
                    ),
                  ),
                );
              },
            );
          }

          if (state is OrderError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64.r,
            color: AppColors.textSecondary.withOpacity(0.2),
          ),
          SizedBox(height: 16.h),
          Text('Belum ada transaksi', style: AppStyles.subtitleStyle),
        ],
      ),
    );
  }
}

class _PremiumHistoryCard extends StatelessWidget {
  final order;
  const _PremiumHistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppStyles.glassDecoration(borderRadius: 24),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        backgroundColor: Colors.white.withOpacity(0.3),
        title: Text(
          '#${order.id.substring(0, 8).toUpperCase()}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt),
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
        trailing: Text(
          CurrencyHelper.formatIdr(order.totalPrice),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 16.sp,
          ),
        ),
        childrenPadding: EdgeInsets.all(20.w),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...order.items
              .map<Widget>(
                (item) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.productName}',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                      Text(
                        CurrencyHelper.formatIdr(item.price * item.quantity),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total:', style: AppStyles.subtitleStyle),
              SizedBox(width: 8.w),
              Text(
                CurrencyHelper.formatIdr(order.totalPrice),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
