import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/currency_helper.dart';
import 'package:pos/features/order/cubit/order_cubit.dart';
import 'package:pos/features/order/cubit/order_state.dart';

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

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return _PremiumHistoryCard(order: order);
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
            size: 64,
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
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Text(
          CurrencyHelper.formatIdr(order.totalPrice),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
        childrenPadding: const EdgeInsets.all(20),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...order.items
              .map<Widget>(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.productName}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        CurrencyHelper.formatIdr(item.price * item.quantity),
                        style: const TextStyle(
                          fontSize: 14,
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
                style: const TextStyle(
                  fontSize: 18,
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
