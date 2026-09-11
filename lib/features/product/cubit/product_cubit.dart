import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pos/core/helper/app_logger.dart';
import 'package:pos/features/product/data/model/product_model.dart';

import '../repository/product_repository.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;
  List<ProductModel> _allProducts = [];
  StreamSubscription? _productSubscription;
  Timer? _searchDebounce;

  ProductCubit(this._repository) : super(ProductInitial()) {
    _subscribeToProductUpdates();
  }

  void _subscribeToProductUpdates() {
    _productSubscription = _repository.productUpdates.listen((_) {
      if (!isClosed) {
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
    } catch (e, stackTrace) {
      AppLogger.error('Gagal memuat produk', error: e, stackTrace: stackTrace);
      emit(ProductError("Gagal memuat produk: $e"));
    }
  }

  void searchProducts(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      if (isClosed) return;
      if (query.trim().isEmpty) {
        emit(ProductLoaded(_allProducts));
        return;
      }

      final searchTerm = query.trim().toLowerCase();
      final filtered = _allProducts.where((product) {
        final name = product.name.toLowerCase();
        final desc = product.description.toLowerCase();
        return name.contains(searchTerm) || desc.contains(searchTerm);
      }).toList();

      emit(ProductLoaded(filtered));
    });
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _repository.addProduct(product);
      await loadProducts(); // Reload list after add
    } catch (e, stackTrace) {
      AppLogger.error(
        'Gagal menambah produk',
        error: e,
        stackTrace: stackTrace,
      );
      emit(ProductError("Gagal menambah produk: $e"));
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _repository.updateProduct(product);
      await loadProducts(); // Reload list after update
    } catch (e, stackTrace) {
      AppLogger.error(
        'Gagal memperbarui produk',
        error: e,
        stackTrace: stackTrace,
      );
      emit(ProductError("Gagal memperbarui produk: $e"));
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await loadProducts(); // Reload list after delete
    } catch (e, stackTrace) {
      AppLogger.error(
        'Gagal menghapus produk',
        error: e,
        stackTrace: stackTrace,
      );
      emit(ProductError("Gagal menghapus produk: $e"));
    }
  }

  Future<void> syncData() async {
    emit(ProductSyncLoading());
    try {
      await _repository.syncPendingData();
      if (isClosed) return;
      emit(ProductSyncSuccess());
      await loadProducts();
    } catch (e, stackTrace) {
      AppLogger.error('Sync data gagal', error: e, stackTrace: stackTrace);
      if (isClosed) return;
      emit(ProductSyncError('Gagal sinkronisasi data: $e'));
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _productSubscription?.cancel();
    return super.close();
  }
}
