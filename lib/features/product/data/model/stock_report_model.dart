import 'package:equatable/equatable.dart';

class StockReportModel extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int systemStock;
  final int manualStock;
  final int adjustment;
  final String note;
  final DateTime createdAt;

  const StockReportModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.systemStock,
    required this.manualStock,
    required this.adjustment,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'system_stock': systemStock,
      'manual_stock': manualStock,
      'adjustment': adjustment,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockReportModel.fromMap(Map<String, dynamic> map) {
    return StockReportModel(
      id: map['id'],
      productId: map['product_id'],
      productName: map['product_name'],
      systemStock: map['system_stock'],
      manualStock: map['manual_stock'],
      adjustment: map['adjustment'],
      note: map['note'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    systemStock,
    manualStock,
    adjustment,
    note,
    createdAt,
  ];
}
