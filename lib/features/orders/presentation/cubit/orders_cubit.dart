import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/load_status.dart';
import '../../../../core/cubit/safe_emit.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/order_usecases.dart';

export '../../../../core/cubit/load_status.dart';

/// `null` status filter means "all".
class OrdersState extends Equatable {
  final LoadStatus status;
  final List<OrderEntity> orders;
  final String? statusFilter;
  final String query;
  final String? error;

  const OrdersState({
    this.status = LoadStatus.loading,
    this.orders = const [],
    this.statusFilter,
    this.query = '',
    this.error,
  });

  List<OrderEntity> get visible {
    Iterable<OrderEntity> list = orders;
    if (statusFilter != null) list = list.where((o) => o.status == statusFilter);
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) =>
          o.customerName.toLowerCase().contains(q) ||
          o.orderNumber.toLowerCase().contains(q) ||
          o.customerPhone.contains(q) ||
          o.items.any((i) => i.productName.toLowerCase().contains(q)));
    }
    return list.toList();
  }

  int countOf(String? status) =>
      status == null ? orders.length : orders.where((o) => o.status == status).length;

  OrderEntity? byId(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  OrdersState copyWith({
    LoadStatus? status,
    List<OrderEntity>? orders,
    String? Function()? statusFilter,
    String? query,
    String? error,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      query: query ?? this.query,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, orders, statusFilter, query, error];
}

/// Real-time order list for any role (admin / customer / worker queue).
class OrdersCubit extends Cubit<OrdersState> with SafeEmit {
  final WatchOrdersUseCase _watchOrders;
  StreamSubscription<List<OrderEntity>>? _sub;
  OrdersQuery? _query;

  OrdersCubit(this._watchOrders) : super(const OrdersState());

  void watch(OrdersQuery query) {
    _query = query;
    _sub?.cancel();
    safeEmit(state.copyWith(status: LoadStatus.loading));
    _sub = _watchOrders(query).listen(
      (list) => safeEmit(state.copyWith(status: LoadStatus.loaded, orders: list)),
      onError: (Object e) => safeEmit(state.copyWith(status: LoadStatus.error, error: e.toString())),
    );
  }

  void retry() {
    if (_query != null) watch(_query!);
  }

  void setStatusFilter(String? status) => safeEmit(state.copyWith(statusFilter: () => status));

  void search(String query) => safeEmit(state.copyWith(query: query));

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
