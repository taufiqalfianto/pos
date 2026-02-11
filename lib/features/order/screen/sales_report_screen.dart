import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/currency_helper.dart';
import '../../order/cubit/sales_report_cubit.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SalesReportCubit>().loadSalesReport();
  }

  void _nextDate(SalesReportLoaded state) {
    final nextDate = state.period == SalesReportPeriod.daily
        ? state.selectedDate.add(const Duration(days: 1))
        : DateTime(state.selectedDate.year, state.selectedDate.month + 1);
    context.read<SalesReportCubit>().loadSalesReport(
      period: state.period,
      date: nextDate,
    );
  }

  void _previousDate(SalesReportLoaded state) {
    final prevDate = state.period == SalesReportPeriod.daily
        ? state.selectedDate.subtract(const Duration(days: 1))
        : DateTime(state.selectedDate.year, state.selectedDate.month - 1);
    context.read<SalesReportCubit>().loadSalesReport(
      period: state.period,
      date: prevDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Penjualan')),
      body: BlocBuilder<SalesReportCubit, SalesReportState>(
        builder: (context, state) {
          if (state is SalesReportLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SalesReportLoaded) {
            return Column(
              children: [
                _buildFilterHeader(state),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryGrid(state),
                        const SizedBox(height: 32),
                        const Text(
                          'Penjualan Per Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCategorySalesList(state.categorySales),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Penjualan:',
                              style: AppStyles.subtitleStyle,
                            ),
                            Text(
                              CurrencyHelper.formatIdr(state.totalRevenue),
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else if (state is SalesReportError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildFilterHeader(SalesReportLoaded state) {
    final dateFormat = state.period == SalesReportPeriod.daily
        ? DateFormat('dd MMMM yyyy', 'id')
        : DateFormat('MMMM yyyy', 'id');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SegmentedButton<SalesReportPeriod>(
            segments: const [
              ButtonSegment(
                value: SalesReportPeriod.daily,
                label: Text('Harian'),
                icon: Icon(Icons.calendar_today),
              ),
              ButtonSegment(
                value: SalesReportPeriod.monthly,
                label: Text('Bulanan'),
                icon: Icon(Icons.calendar_month),
              ),
            ],
            selected: {state.period},
            onSelectionChanged: (newSelection) {
              context.read<SalesReportCubit>().loadSalesReport(
                period: newSelection.first,
                date: state.selectedDate,
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _previousDate(state),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                dateFormat.format(state.selectedDate),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: () => _nextDate(state),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(SalesReportLoaded state) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          'Total Pesanan',
          '${state.totalOrders}',
          Icons.shopping_bag_outlined,
          AppColors.primary,
        ),
        _buildStatCard(
          'Total Pendapatan',
          CurrencyHelper.formatIdr(state.totalRevenue),
          Icons.account_balance_wallet_outlined,
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.glassDecoration(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySalesList(List<Map<String, dynamic>> categorySales) {
    if (categorySales.isEmpty) {
      return Center(
        child: Text('Belum ada data penjualan', style: AppStyles.subtitleStyle),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categorySales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = categorySales[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category['category_name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                CurrencyHelper.formatIdr(
                  (category['revenue'] as num).toDouble(),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
