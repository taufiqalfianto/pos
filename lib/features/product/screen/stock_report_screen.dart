import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/util/app_style.dart';
import '../cubit/stock_report_cubit.dart';
import '../data/model/product_model.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Stok')),
      body: Column(
        children: [
          _buildSummaryCard(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  'Riwayat Penyesuaian',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(child: _buildHistoryList()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            height: 60,
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
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: AppStyles.glassDecoration(borderRadius: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                    size: 48,
                    color: AppColors.textSecondary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text('Belum ada riwayat', style: AppStyles.subtitleStyle),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final report = state.reports[index];
              final isPositive = report.adjustment > 0;
              final adjText = isPositive
                  ? '+${report.adjustment}'
                  : '${report.adjustment}';
              final adjColor = isPositive ? AppColors.success : AppColors.error;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: adjColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            adjText,
                            style: TextStyle(
                              color: adjColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
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
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
