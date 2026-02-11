import 'package:equatable/equatable.dart';

class OrderItemModel extends Equatable {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap(String orderId) {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['product_id'],
      productName: map['product_name'],
      price: map['price'],
      quantity: map['quantity'],
    );
  }

  @override
  List<Object?> get props => [productId, productName, price, quantity];
}

class OrderModel extends Equatable {
  final String id;
  final List<OrderItemModel> items;
  final double totalPrice;
  final DateTime createdAt;
  final int day;
  final int month;
  final int year;

  const OrderModel({
    required this.id,
    required this.items,
    required this.totalPrice,
    required this.createdAt,
    required this.day,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'day': day,
      'month': month,
      'year': year,
    };
  }

  factory OrderModel.fromMap(
    Map<String, dynamic> map,
    List<OrderItemModel> items,
  ) {
    return OrderModel(
      id: map['id'],
      totalPrice: map['total_price'],
      createdAt: DateTime.parse(map['created_at']),
      day: map['day'] ?? DateTime.parse(map['created_at']).day,
      month: map['month'] ?? DateTime.parse(map['created_at']).month,
      year: map['year'] ?? DateTime.parse(map['created_at']).year,
      items: items,
    );
  }

  @override
  List<Object?> get props => [
    id,
    items,
    totalPrice,
    createdAt,
    day,
    month,
    year,
  ];
}
