import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/model/stock_report_model.dart';
import '../repository/product_repository.dart';

// States
abstract class StockReportState extends Equatable {
  const StockReportState();

  @override
  List<Object?> get props => [];
}

class StockReportInitial extends StockReportState {}

class StockReportLoading extends StockReportState {}

class StockHistoryLoaded extends StockReportState {
  final List<StockReportModel> reports;
  const StockHistoryLoaded(this.reports);

  @override
  List<Object?> get props => [reports];
}

class StockReportSuccess extends StockReportState {}

class StockReportError extends StockReportState {
  final String message;
  const StockReportError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class StockReportCubit extends Cubit<StockReportState> {
  final ProductRepository _repository;

  StockReportCubit(this._repository) : super(StockReportInitial());

  Future<void> loadReports(String productId) async {
    emit(StockReportLoading());
    try {
      final reports = await _repository.getStockReports(productId);
      emit(StockHistoryLoaded(reports));
    } catch (e) {
      emit(StockReportError('Gagal memuat riwayat stok: $e'));
    }
  }

  Future<void> submitReport(StockReportModel report) async {
    emit(StockReportLoading());
    try {
      await _repository.saveStockReport(report);
      emit(StockReportSuccess());
      loadReports(report.productId);
    } catch (e) {
      emit(StockReportError('Gagal menyimpan laporan: $e'));
    }
  }
}
