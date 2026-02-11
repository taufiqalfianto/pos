import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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
  final List<Map<String, dynamic>> categorySales;
  final SalesReportPeriod period;
  final DateTime selectedDate;

  const SalesReportLoaded({
    required this.totalOrders,
    required this.totalRevenue,
    required this.categorySales,
    required this.period,
    required this.selectedDate,
  });

  @override
  List<Object?> get props => [
    totalOrders,
    totalRevenue,
    categorySales,
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
  final OrderRepository _repository;

  SalesReportCubit(this._repository) : super(SalesReportInitial());

  Future<void> loadSalesReport({
    SalesReportPeriod period = SalesReportPeriod.daily,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
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
          categorySales: List<Map<String, dynamic>>.from(
            report['category_sales'],
          ),
          period: period,
          selectedDate: targetDate,
        ),
      );
    } catch (e) {
      emit(SalesReportError('Gagal memuat laporan penjualan: $e'));
    }
  }
}
