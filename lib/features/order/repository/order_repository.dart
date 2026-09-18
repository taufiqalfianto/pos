import 'package:pos/core/helper/app_logger.dart';
import 'package:pos/core/helper/database_helper.dart';
import '../data/model/order_model.dart';

class OrderRepository {
  static const _logTag = 'OrderRepository';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> saveOrder(OrderModel order) async {
    AppLogger.info(
      'Simpan order dimulai: order_id=${order.id}, item_count=${order.items.length}, total=${order.totalPrice}, payment=${order.paymentMethod}',
      tag: _logTag,
    );
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
          AppLogger.warning(
            'Simpan order gagal: product tidak ditemukan, order_id=${order.id}, product_id=${item.productId}',
            tag: _logTag,
          );
          throw Exception('Produk "${item.productName}" tidak ditemukan');
        }

        final int currentStock = productResult.first['stock'] as int;
        final int newStock = currentStock - item.quantity;

        if (newStock < 0) {
          AppLogger.warning(
            'Simpan order gagal: stok kurang, order_id=${order.id}, product_id=${item.productId}, requested=${item.quantity}, stock=$currentStock',
            tag: _logTag,
          );
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
    AppLogger.info('Simpan order berhasil: order_id=${order.id}', tag: _logTag);
  }

  Future<List<OrderModel>> getOrders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> ordersMap = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );

    if (ordersMap.isEmpty) {
      AppLogger.debug('Riwayat order kosong', tag: _logTag);
      return [];
    }

    final List<Map<String, dynamic>> allItemsMap = await db.query(
      'order_items',
    );

    final Map<String, List<OrderItemModel>> itemsByOrderId = {};
    for (final itemMap in allItemsMap) {
      final orderId = itemMap['order_id'] as String?;
      if (orderId != null) {
        final item = OrderItemModel.fromMap(itemMap);
        (itemsByOrderId[orderId] ??= []).add(item);
      }
    }

    final orders = ordersMap.map((map) {
      final orderId = map['id'] as String;
      final items = itemsByOrderId[orderId] ?? [];
      return OrderModel.fromMap(map, items);
    }).toList();
    AppLogger.debug(
      'Riwayat order dimuat: count=${orders.length}',
      tag: _logTag,
    );
    return orders;
  }

  // Sales Report Aggregation
  Future<Map<String, dynamic>> getSalesReport({
    int? day,
    int? month,
    int? year,
    String period = 'daily',
  }) async {
    AppLogger.info(
      'Load sales report dimulai: period=$period, day=$day, month=$month, year=$year',
      tag: _logTag,
    );
    final db = await _dbHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (period == 'daily') {
      whereClause = 'WHERE o.day = ? AND o.month = ? AND o.year = ?';
      whereArgs = [day, month, year];
    } else if (period == 'monthly') {
      whereClause = 'WHERE o.month = ? AND o.year = ?';
      whereArgs = [month, year];
    } else if (period == 'yearly') {
      // Future proofing
      whereClause = 'WHERE o.year = ?';
      whereArgs = [year];
    }

    final totalSalesResult = await db.rawQuery('''
      SELECT
        COUNT(DISTINCT o.id) as count,
        COALESCE(SUM(oi.price * oi.quantity), 0) as revenue,
        COALESCE(SUM(oi.cost_price * oi.quantity), 0) as cost,
        COALESCE(SUM((oi.price - oi.cost_price) * oi.quantity), 0) as profit
      FROM orders o
      LEFT JOIN order_items oi ON oi.order_id = o.id
      $whereClause
    ''', whereArgs);
    final totalSalesCount = totalSalesResult.first['count'] as int? ?? 0;
    final totalRevenue =
        (totalSalesResult.first['revenue'] as num?)?.toDouble() ?? 0.0;
    final totalCost =
        (totalSalesResult.first['cost'] as num?)?.toDouble() ?? 0.0;
    final totalProfit =
        (totalSalesResult.first['profit'] as num?)?.toDouble() ?? 0.0;

    final categorySalesResult = await db.rawQuery('''
      SELECT
        c.name as category_name,
        COALESCE(SUM(oi.price * oi.quantity), 0) as revenue,
        COALESCE(SUM(oi.cost_price * oi.quantity), 0) as cost,
        COALESCE(SUM((oi.price - oi.cost_price) * oi.quantity), 0) as profit
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      JOIN products p ON oi.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      $whereClause
      GROUP BY c.id
    ''', whereArgs);

    final paymentSalesResult = await db.rawQuery('''
      SELECT
        o.payment_method as payment_method,
        COUNT(DISTINCT o.id) as count,
        COALESCE(SUM(oi.price * oi.quantity), 0) as revenue
      FROM orders o
      LEFT JOIN order_items oi ON oi.order_id = o.id
      $whereClause
      GROUP BY o.payment_method
      ORDER BY revenue DESC
    ''', whereArgs);

    final report = {
      'total_orders': totalSalesCount,
      'total_revenue': totalRevenue,
      'total_cost': totalCost,
      'total_profit': totalProfit,
      'category_sales': categorySalesResult,
      'payment_sales': paymentSalesResult,
    };
    AppLogger.info(
      'Load sales report berhasil: period=$period, total_orders=$totalSalesCount, revenue=$totalRevenue, profit=$totalProfit',
      tag: _logTag,
    );
    return report;
  }
}
