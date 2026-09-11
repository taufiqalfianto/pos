import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/order/data/model/order_model.dart';

void main() {
  test('OrderModel menyimpan metode pembayaran ke map', () {
    final createdAt = DateTime(2026, 9, 11, 10, 30);
    final order = OrderModel(
      id: 'order-1',
      items: const [],
      totalPrice: 25000,
      paymentMethod: 'qris',
      createdAt: createdAt,
      day: 11,
      month: 9,
      year: 2026,
    );

    expect(order.toMap(), {
      'id': 'order-1',
      'total_price': 25000.0,
      'payment_method': 'qris',
      'created_at': createdAt.toIso8601String(),
      'day': 11,
      'month': 9,
      'year': 2026,
    });
  });

  test(
    'OrderModel fromMap memakai cash untuk data lama tanpa payment_method',
    () {
      final order = OrderModel.fromMap({
        'id': 'order-1',
        'total_price': 25000,
        'created_at': '2026-09-11T10:30:00.000',
        'day': 11,
        'month': 9,
        'year': 2026,
      }, const []);

      expect(order.paymentMethod, 'cash');
    },
  );
}
