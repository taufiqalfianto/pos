import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../product/data/model/product_model.dart';
import '../../product/repository/product_repository.dart';
import '../data/model/order_model.dart';
import '../repository/order_repository.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;

  List<OrderItemModel> _cartItems = [];

  OrderCubit(this._orderRepository, this._productRepository)
    : super(OrderInitial());

  void addItem(ProductModel product) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      final item = _cartItems[existingIndex];
      // Check stock
      if (item.quantity + 1 > product.stock) {
        emit(const OrderError('Stok tidak mencukupi'));
        emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
        return;
      }

      _cartItems[existingIndex] = OrderItemModel(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity + 1,
      );
    } else {
      // Check stock for new item
      if (product.stock < 1) {
        emit(const OrderError('Stok habis'));
        emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
        return;
      }

      _cartItems.add(
        OrderItemModel(
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: 1,
        ),
      );
    }

    emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
  }

  void removeItem(String productId) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        final item = _cartItems[index];
        _cartItems[index] = OrderItemModel(
          productId: item.productId,
          productName: item.productName,
          price: item.price,
          quantity: item.quantity - 1,
        );
      } else {
        _cartItems.removeAt(index);
      }
    }
    emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        final item = _cartItems[index];

        // Only check if increasing quantity
        if (quantity > item.quantity) {
          final product = await _productRepository.getProductById(productId);
          if (product != null && quantity > product.stock) {
            emit(const OrderError('Stok tidak mencukupi'));
            emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
            return;
          }
        }

        _cartItems[index] = OrderItemModel(
          productId: item.productId,
          productName: item.productName,
          price: item.price,
          quantity: quantity,
        );
      }
      emit(OrderCartUpdated(List.from(_cartItems), _calculateTotal()));
    }
  }

  void clearCart() {
    _cartItems = [];
    emit(OrderInitial());
  }

  double _calculateTotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  Future<void> checkout() async {
    if (_cartItems.isEmpty) return;

    try {
      emit(OrderLoading());

      final now = DateTime.now();
      final order = OrderModel(
        id: const Uuid().v4(),
        items: List.from(_cartItems),
        totalPrice: _calculateTotal(),
        createdAt: now,
        day: now.day,
        month: now.month,
        year: now.year,
      );

      // Save to DB (this also reduces stock atomically)
      await _orderRepository.saveOrder(order);

      // Notify product listeners that stock has changed
      _productRepository.notifyListeners();

      _cartItems = [];
      emit(OrderSuccess(order));
    } catch (e) {
      // The exception message from OrderRepository will be used here
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
      emit(OrderLoading());
      final orders = await _orderRepository.getOrders();
      emit(OrderHistoryLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}
