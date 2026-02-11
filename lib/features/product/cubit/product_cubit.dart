import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pos/features/product/data/model/product_model.dart';

import '../repository/product_repository.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;
  List<ProductModel> _allProducts = [];
  StreamSubscription? _productSubscription;
  bool _isDisposed = false;

  ProductCubit(this._repository) : super(ProductInitial()) {
    _subscribeToProductUpdates();
  }

  void _subscribeToProductUpdates() {
    _productSubscription = _repository.productUpdates.listen((_) {
      if (!_isDisposed) {
        loadProducts();
      }
    });
  }

  Future<void> loadProducts() async {
    emit(ProductLoading());
    try {
      final products = await _repository.getProducts();
      _allProducts = products;
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError("Gagal memuat produk: $e"));
    }
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      emit(ProductLoaded(_allProducts));
      return;
    }

    final filtered = _allProducts.where((product) {
      final name = product.name.toLowerCase();
      final desc = product.description.toLowerCase();
      final searchTerm = query.toLowerCase();
      return name.contains(searchTerm) || desc.contains(searchTerm);
    }).toList();

    emit(ProductLoaded(filtered));
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _repository.addProduct(product);
      loadProducts(); // Reload list after add
    } catch (e) {
      emit(ProductError("Gagal menambah produk"));
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _repository.updateProduct(product);
      loadProducts(); // Reload list after update
    } catch (e) {
      emit(ProductError("Gagal memperbarui produk"));
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      loadProducts(); // Reload list after delete
    } catch (e) {
      emit(ProductError("Gagal menghapus produk"));
    }
  }

  Future<void> syncData() async {
    // Kita biarkan state tetap loaded, tapi beri notifikasi atau loading overlay di UI
    // Disini kita refresh list setelah sync selesai
    try {
      await _repository.syncPendingData();
      loadProducts();
    } catch (e) {
      // Silent fail or show snackbar in UI
    }
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    _productSubscription?.cancel();
    return super.close();
  }
}
