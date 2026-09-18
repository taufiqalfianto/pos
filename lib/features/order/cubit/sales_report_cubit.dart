import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/helper/app_logger.dart';
import '../repository/order_repository.dart';

enum SalesReportPeriod { daily, monthly }

// States
abstract class SalesReportState extends Equatable {
  const SalesReportState();
  @override
  List<Object?> get props => [];
}

class SalesReportInitial extends SalesReportState {}

class SalesReportLoading extends SalesReportState {}

class SalesReportLoaded extends SalesReportState {
  final int totalOrders;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final List<Map<String, dynamic>> categorySales;
  final List<Map<String, dynamic>> paymentSales;
  final SalesReportPeriod period;
  final DateTime selectedDate;

  const SalesReportLoaded({
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.categorySales,
    required this.paymentSales,
    required this.period,
    required this.selectedDate,
  });

  @override
  List<Object?> get props => [
    totalOrders,
    totalRevenue,
    totalCost,
    totalProfit,
    categorySales,
    paymentSales,
    period,
    selectedDate,
  ];
}

class SalesReportError extends SalesReportState {
  final String message;
  const SalesReportError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class SalesReportCubit extends Cubit<SalesReportState> {
  static const _logTag = 'SalesReportCubit';
  final OrderRepository _repository;

  SalesReportCubit(this._repository) : super(SalesReportInitial());

  Future<void> refreshCurrentReport() {
    AppLogger.info('Refresh current sales report dimulai', tag: _logTag);
    final currentState = state;
    if (currentState is SalesReportLoaded) {
      return loadSalesReport(
        period: currentState.period,
        date: currentState.selectedDate,
      );
    }
    return loadSalesReport();
  }

  Future<void> loadSalesReport({
    SalesReportPeriod period = SalesReportPeriod.daily,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    AppLogger.info(
      'Load sales report action dimulai: period=$period, date=${targetDate.toIso8601String()}',
      tag: _logTag,
    );
    emit(SalesReportLoading());
    try {
      final report = await _repository.getSalesReport(
        day: targetDate.day,
        month: targetDate.month,
        year: targetDate.year,
        period: period == SalesReportPeriod.daily ? 'daily' : 'monthly',
      );
      emit(
        SalesReportLoaded(
          totalOrders: report['total_orders'],
          totalRevenue: report['total_revenue'],
          totalCost: report['total_cost'],
          totalProfit: report['total_profit'],
          categorySales: List<Map<String, dynamic>>.from(
            report['category_sales'],
          ),
          paymentSales: List<Map<String, dynamic>>.from(
            report['payment_sales'],
          ),
          period: period,
          selectedDate: targetDate,
        ),
      );
      AppLogger.info(
        'Load sales report action berhasil: period=$period, total_orders=${report['total_orders']}',
        tag: _logTag,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Load sales report action gagal',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      emit(SalesReportError('Gagal memuat laporan penjualan: $e'));
    }
  }
}
