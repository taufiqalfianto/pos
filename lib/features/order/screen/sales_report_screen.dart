import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/currency_helper.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/features/order/cubit/order_cubit.dart';
import 'package:pos/features/order/cubit/order_state.dart';
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
      body: BlocListener<OrderCubit, OrderState>(
        listenWhen: (previous, current) => current is OrderSuccess,
        listener: (context, state) =>
            context.read<SalesReportCubit>().refreshCurrentReport(),
        child: BlocBuilder<SalesReportCubit, SalesReportState>(
          builder: (context, state) {
            if (state is SalesReportLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SalesReportLoaded) {
              return LayoutBuilder(
                builder: (context, _) {
                  return Column(
                    children: [
                      _buildFilterHeader(state),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: context
                              .read<SalesReportCubit>()
                              .refreshCurrentReport,
                          color: AppColors.primary,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: ResponsiveLayout.pagePadding(context),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: ResponsiveLayout.contentMaxWidth(
                                    context,
                                    maxWidth: 980,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSummaryGrid(context, state),
                                    SizedBox(height: 32.h),
                                    Text(
                                      'Penjualan Per Kategori',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    _buildCategorySalesList(
                                      state.categorySales,
                                    ),
                                    SizedBox(height: 32.h),
                                    _buildTotalRow(
                                      'Total Penjualan:',
                                      state.totalRevenue,
                                      AppColors.primary,
                                    ),
                                    SizedBox(height: 12.h),
                                    _buildTotalRow(
                                      'Total Modal:',
                                      state.totalCost,
                                      AppColors.tertiary,
                                    ),
                                    SizedBox(height: 12.h),
                                    _buildTotalRow(
                                      'Keuntungan:',
                                      state.totalProfit,
                                      state.totalProfit >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            } else if (state is SalesReportError) {
              return Center(child: Text(state.message));
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildFilterHeader(SalesReportLoaded state) {
    final dateFormat = state.period == SalesReportPeriod.daily
        ? DateFormat('dd MMMM yyyy', 'id')
        : DateFormat('MMMM yyyy', 'id');

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
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
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _previousDate(state),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                dateFormat.format(state.selectedDate),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
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

  Widget _buildSummaryGrid(BuildContext context, SalesReportLoaded state) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: ResponsiveLayout.gridColumns(
        context,
        portrait: 2,
        landscape: 2,
        wide: 3,
        desktop: 4,
      ),
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: 0.85,
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
        _buildStatCard(
          'Total Modal',
          CurrencyHelper.formatIdr(state.totalCost),
          Icons.savings_outlined,
          AppColors.tertiary,
        ),
        _buildStatCard(
          'Keuntungan',
          CurrencyHelper.formatIdr(state.totalProfit),
          Icons.trending_up_rounded,
          state.totalProfit >= 0 ? AppColors.success : AppColors.error,
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
      padding: EdgeInsets.all(20.w),
      decoration: AppStyles.glassDecoration(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.r),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
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
      separatorBuilder: (context, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final category = categorySales[index];
        final revenue = (category['revenue'] as num?)?.toDouble() ?? 0;
        final cost = (category['cost'] as num?)?.toDouble() ?? 0;
        final profit = (category['profit'] as num?)?.toDouble() ?? 0;

        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['category_name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Modal: ${CurrencyHelper.formatIdr(cost)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyHelper.formatIdr(revenue),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Untung: ${CurrencyHelper.formatIdr(profit)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: profit >= 0 ? AppColors.success : AppColors.error,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppStyles.subtitleStyle),
        SizedBox(width: 16.w),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              CurrencyHelper.formatIdr(value),
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
