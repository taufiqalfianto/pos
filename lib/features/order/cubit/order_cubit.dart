import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/helper/app_logger.dart';
import '../../product/data/model/product_model.dart';
import '../../product/repository/product_repository.dart';
import '../data/model/order_model.dart';
import '../repository/order_repository.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  static const _logTag = 'OrderCubit';
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;

  List<OrderItemModel> _cartItems = [];
  List<OrderItemModel> get cartItems => List.unmodifiable(_cartItems);
  double get cartTotal => _calculateTotal();

  OrderCubit(this._orderRepository, this._productRepository)
    : super(OrderInitial());

  void addItem(ProductModel product) {
    AppLogger.info('Tambah item cart: product_id=${product.id}', tag: _logTag);
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      final item = _cartItems[existingIndex];
      if (item.quantity + 1 > product.stock) {
        AppLogger.warning(
          'Tambah item cart ditolak: stok kurang, product_id=${product.id}',
          tag: _logTag,
        );
        emit(const OrderError('Stok tidak mencukupi'));
        emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
        return;
      }

      _cartItems[existingIndex] = OrderItemModel(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        costPrice: item.costPrice,
        quantity: item.quantity + 1,
      );
    } else {
      if (product.stock < 1) {
        AppLogger.warning(
          'Tambah item cart ditolak: stok habis, product_id=${product.id}',
          tag: _logTag,
        );
        emit(const OrderError('Stok habis'));
        emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
        return;
      }

      _cartItems.add(
        OrderItemModel(
          productId: product.id,
          productName: product.name,
          price: product.price,
          costPrice: product.costPrice,
          quantity: 1,
        ),
      );
    }

    AppLogger.debug(
      'Cart updated setelah tambah item: item_count=${_cartItems.length}, total=${_calculateTotal()}',
      tag: _logTag,
    );
    emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
  }

  void removeItem(String productId) {
    AppLogger.info(
      'Kurangi/hapus item cart: product_id=$productId',
      tag: _logTag,
    );
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index < 0) {
      AppLogger.warning(
        'Item cart tidak ditemukan: product_id=$productId',
        tag: _logTag,
      );
      return;
    }

    if (_cartItems[index].quantity > 1) {
      final item = _cartItems[index];
      _cartItems[index] = OrderItemModel(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        costPrice: item.costPrice,
        quantity: item.quantity - 1,
      );
    } else {
      _cartItems.removeAt(index);
    }
    AppLogger.debug(
      'Cart updated setelah remove item: item_count=${_cartItems.length}, total=${_calculateTotal()}',
      tag: _logTag,
    );
    emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    AppLogger.info(
      'Update quantity cart dimulai: product_id=$productId, quantity=$quantity',
      tag: _logTag,
    );
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index < 0) {
      AppLogger.warning(
        'Update quantity gagal: item tidak ditemukan',
        tag: _logTag,
      );
      return;
    }

    if (quantity <= 0) {
      _cartItems.removeAt(index);
      AppLogger.info(
        'Item cart dihapus lewat quantity <= 0: product_id=$productId',
        tag: _logTag,
      );
      emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
      return;
    }

    if (quantity > _cartItems[index].quantity) {
      try {
        final product = await _productRepository.getProductById(productId);
        if (product != null && quantity > product.stock) {
          AppLogger.warning(
            'Update quantity ditolak: stok kurang, product_id=$productId, requested=$quantity, stock=${product.stock}',
            tag: _logTag,
          );
          emit(const OrderError('Stok tidak mencukupi'));
          emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
          return;
        }
      } catch (e, stackTrace) {
        AppLogger.error('Gagal cek stok', error: e, stackTrace: stackTrace);
        emit(const OrderError('Gagal memeriksa stok produk'));
        return;
      }
    }

    final item = _cartItems[index];
    _cartItems[index] = OrderItemModel(
      productId: item.productId,
      productName: item.productName,
      price: item.price,
      costPrice: item.costPrice,
      quantity: quantity,
    );
    AppLogger.debug(
      'Cart updated setelah update quantity: item_count=${_cartItems.length}, total=${_calculateTotal()}',
      tag: _logTag,
    );
    emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
  }

  void clearCart() {
    AppLogger.info(
      'Cart dikosongkan: previous_item_count=${_cartItems.length}',
      tag: _logTag,
    );
    _cartItems = [];
    emit(OrderInitial());
  }

  double _calculateTotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  Future<void> checkout({required String paymentMethod}) async {
    if (_cartItems.isEmpty) {
      AppLogger.warning('Checkout dilewati: cart kosong', tag: _logTag);
      return;
    }

    try {
      AppLogger.info(
        'Checkout dimulai: item_count=${_cartItems.length}, total=${_calculateTotal()}, payment=$paymentMethod',
        tag: _logTag,
      );
      emit(OrderLoading());

      final now = DateTime.now();
      final order = OrderModel(
        id: const Uuid().v4(),
        items: List.from(_cartItems),
        totalPrice: _calculateTotal(),
        paymentMethod: paymentMethod,
        createdAt: now,
        day: now.day,
        month: now.month,
        year: now.year,
      );

      await _orderRepository.saveOrder(order);
      _productRepository.notifyListeners();

      _cartItems = [];
      AppLogger.info('Checkout berhasil: order_id=${order.id}', tag: _logTag);
      emit(OrderSuccess(order));
    } catch (e, stackTrace) {
      AppLogger.error('Checkout gagal', error: e, stackTrace: stackTrace);
      String message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.substring(11);
      }
      emit(OrderError(message));
      emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
    }
  }

  Future<void> fetchOrderHistory() async {
    try {
      AppLogger.info('Load riwayat order dimulai', tag: _logTag);
      emit(OrderLoading());
      final orders = await _orderRepository.getOrders();
      AppLogger.info(
        'Load riwayat order berhasil: count=${orders.length}',
        tag: _logTag,
      );
      emit(OrderHistoryLoaded(orders));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Gagal memuat riwayat order',
        error: e,
        stackTrace: stackTrace,
      );
      emit(OrderError(e.toString()));
    }
  }
}
