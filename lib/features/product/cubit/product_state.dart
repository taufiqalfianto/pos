part of 'product_cubit.dart';

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  final DateTime? lastSyncAt;

  const ProductLoaded(this.products, {this.lastSyncAt});

  @override
  List<Object?> get props => [products, lastSyncAt];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
}

class ProductSyncLoading extends ProductState {
  final List<ProductModel> products;
  final DateTime? lastSyncAt;

  const ProductSyncLoading({this.products = const [], this.lastSyncAt});

  @override
  List<Object?> get props => [products, lastSyncAt];
}

class ProductSyncSuccess extends ProductState {
  final DateTime lastSyncAt;

  const ProductSyncSuccess(this.lastSyncAt);

  @override
  List<Object?> get props => [lastSyncAt];
}

class ProductSyncError extends ProductState {
  final String message;
  final DateTime? lastSyncAt;

  const ProductSyncError(this.message, {this.lastSyncAt});

  @override
  List<Object?> get props => [message, lastSyncAt];
}
