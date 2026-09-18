import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/helper/app_logger.dart';
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
  static const _logTag = 'StockReportCubit';
  final ProductRepository _repository;

  StockReportCubit(this._repository) : super(StockReportInitial());

  Future<void> loadReports(String productId) async {
    AppLogger.info(
      'Load laporan stok dimulai: product_id=$productId',
      tag: _logTag,
    );
    emit(StockReportLoading());
    try {
      final reports = await _repository.getStockReports(productId);
      AppLogger.info(
        'Load laporan stok berhasil: product_id=$productId, count=${reports.length}',
        tag: _logTag,
      );
      emit(StockHistoryLoaded(reports));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Load laporan stok gagal: product_id=$productId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      emit(StockReportError('Gagal memuat riwayat stok: $e'));
    }
  }

  Future<void> submitReport(StockReportModel report) async {
    AppLogger.info(
      'Submit laporan stok dimulai: report_id=${report.id}, product_id=${report.productId}',
      tag: _logTag,
    );
    emit(StockReportLoading());
    try {
      await _repository.saveStockReport(report);
      AppLogger.info(
        'Submit laporan stok berhasil: report_id=${report.id}, adjustment=${report.adjustment}',
        tag: _logTag,
      );
      emit(StockReportSuccess());
      loadReports(report.productId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Submit laporan stok gagal: report_id=${report.id}',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      emit(StockReportError('Gagal menyimpan laporan: $e'));
    }
  }
}
