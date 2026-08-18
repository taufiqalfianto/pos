import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';
import '../cubit/stock_report_cubit.dart';
import '../data/model/product_model.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class StockReportScreen extends StatefulWidget {
  final ProductModel product;
  const StockReportScreen({super.key, required this.product});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StockReportCubit>().loadReports(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = context.isLandscape;
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Stok')),
      body: Column(
        children: [
          _buildSummaryCard(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 20 : 24.w,
              vertical: isLandscape ? 10 : 16.h,
            ),
            child: Row(
              children: [
                Text(
                  'Riwayat Penyesuaian',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isLandscape ? 14.sp : 16.sp,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildHistoryList()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(
            context,
            portrait: 24,
            landscape: 32,
            vertical: isLandscape ? 16 : 24,
          ),
          child: SizedBox(
            height: ResponsiveLayout.adaptiveValue(
              context,
              portrait: 60,
              landscape: 52,
              tablet: 52,
            ),
            child: FilledButton.icon(
              onPressed: () =>
                  context.push('/add-stock-report', extra: widget.product),
              icon: const Icon(Icons.add_chart_rounded),
              label: const Text(
                'INPUT STOK MANUAL',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final isLandscape = context.isLandscape;
    return Container(
      margin: EdgeInsets.all(isLandscape ? 16 : 24.w),
      padding: EdgeInsets.all(isLandscape ? 14 : 24.w),
      decoration: AppStyles.glassDecoration(
        borderRadius: isLandscape ? 24 : 32,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isLandscape ? 10 : 16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isLandscape ? 14 : 20.r),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: AppColors.primary,
              size: isLandscape ? 26 : 32.r,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isLandscape ? 15.sp : 18.sp,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stok Sistem Saat Ini: ${widget.product.stock}',
                  style: AppStyles.subtitleStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return BlocBuilder<StockReportCubit, StockReportState>(
      builder: (context, state) {
        if (state is StockReportLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is StockHistoryLoaded) {
          if (state.reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48.r,
                    color: AppColors.textSecondary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text('Belum ada riwayat', style: AppStyles.subtitleStyle),
                ],
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, _) {
              final maxWidth = ResponsiveLayout.contentMaxWidth(
                context,
                maxWidth: 760,
              );
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ListView.separated(
                    padding: ResponsiveLayout.pagePadding(context),
                    itemCount: state.reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = state.reports[index];
                      final isPositive = report.adjustment > 0;
                      final adjText = isPositive
                          ? '+${report.adjustment}'
                          : '${report.adjustment}';
                      final adjColor = isPositive
                          ? AppColors.success
                          : AppColors.error;

                      return Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy, HH:mm',
                                  ).format(report.createdAt),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: adjColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    adjText,
                                    style: TextStyle(
                                      color: adjColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _infoItem('Sistem', '${report.systemStock}'),
                                const SizedBox(width: 24),
                                _infoItem('Manual', '${report.manualStock}'),
                              ],
                            ),
                            if (report.note.isNotEmpty) ...[
                              const Divider(height: 24),
                              Text(
                                report.note,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
      ],
    );
  }
}
