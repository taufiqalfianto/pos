import 'package:equatable/equatable.dart';
import '../data/model/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderCartUpdated extends OrderState {
  final List<OrderItemModel> items;
  final double total;

  const OrderCartUpdated(this.items, this.total);

  @override
  List<Object?> get props => [items, total];
}

class OrderSuccess extends OrderState {
  final OrderModel order;
  const OrderSuccess(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderHistoryLoaded extends OrderState {
  final List<OrderModel> orders;
  const OrderHistoryLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
