import 'package:pos/core/helper/database_helper.dart';
import '../data/model/order_model.dart';

class OrderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> saveOrder(OrderModel order) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Save order
      await txn.insert('orders', order.toMap());

      // 2. Save order items & Reduce Stock
      for (final item in order.items) {
        await txn.insert('order_items', item.toMap(order.id));

        // Get current stock
        final List<Map<String, dynamic>> productResult = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        if (productResult.isEmpty) {
          throw Exception('Produk "${item.productName}" tidak ditemukan');
        }

        final int currentStock = productResult.first['stock'] as int;
        final int newStock = currentStock - item.quantity;

        if (newStock < 0) {
          throw Exception('Stok untuk "${item.productName}" tidak mencukupi');
        }

        // Update stock (mark as not synced)
        await txn.update(
          'products',
          {'stock': newStock, 'is_synced': 0},
          where: 'id = ?',
          whereArgs: [item.productId],
        );
      }
    });
  }

  Future<List<OrderModel>> getOrders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> ordersMap = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );

    List<OrderModel> orders = [];
    for (var map in ordersMap) {
      final List<Map<String, dynamic>> itemsMap = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [map['id']],
      );

      final items = itemsMap.map((i) => OrderItemModel.fromMap(i)).toList();
      orders.add(OrderModel.fromMap(map, items));
    }

    return orders;
  }

  // Sales Report Aggregation
  Future<Map<String, dynamic>> getSalesReport({
    int? day,
    int? month,
    int? year,
    String period = 'daily',
  }) async {
    final db = await _dbHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (period == 'daily') {
      whereClause = 'WHERE day = ? AND month = ? AND year = ?';
      whereArgs = [day, month, year];
    } else if (period == 'monthly') {
      whereClause = 'WHERE month = ? AND year = ?';
      whereArgs = [month, year];
    } else if (period == 'yearly') {
      // Future proofing
      whereClause = 'WHERE year = ?';
      whereArgs = [year];
    }

    final totalSalesResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(total_price) as revenue FROM orders $whereClause',
      whereArgs,
    );
    final totalSalesCount = totalSalesResult.first['count'] as int? ?? 0;
    final totalRevenue =
        (totalSalesResult.first['revenue'] as num?)?.toDouble() ?? 0.0;

    final categorySalesResult = await db.rawQuery('''
      SELECT c.name as category_name, SUM(oi.price * oi.quantity) as revenue
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      JOIN products p ON oi.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      $whereClause
      GROUP BY c.id
    ''', whereArgs);

    return {
      'total_orders': totalSalesCount,
      'total_revenue': totalRevenue,
      'category_sales': categorySalesResult,
    };
  }
}
