import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/load_status.dart';
import '../../../../core/cubit/safe_emit.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/product_usecases.dart';

export '../../../../core/cubit/load_status.dart';

/// Admin-side quick filter.
enum ProductFilter { all, available, lowStock, outOfStock, hidden }

class ProductsState extends Equatable {
  final LoadStatus status;
  final List<ProductEntity> products;
  final String query;
  final ProductFilter filter;
  final String? error;

  const ProductsState({
    this.status = LoadStatus.loading,
    this.products = const [],
    this.query = '',
    this.filter = ProductFilter.all,
    this.error,
  });

  List<ProductEntity> get visible {
    Iterable<ProductEntity> list = products;
    switch (filter) {
      case ProductFilter.all:
        break;
      case ProductFilter.available:
        list = list.where((p) => p.isActive && !p.isOutOfStock);
      case ProductFilter.lowStock:
        list = list.where((p) => p.isActive && p.isLowStock);
      case ProductFilter.outOfStock:
        list = list.where((p) => p.isActive && p.isOutOfStock);
      case ProductFilter.hidden:
        list = list.where((p) => !p.isActive);
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where(
        (p) => p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q),
      );
    }
    return list.toList();
  }

  ProductEntity? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  ProductsState copyWith({
    LoadStatus? status,
    List<ProductEntity>? products,
    String? query,
    ProductFilter? filter,
    String? error,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, products, query, filter, error];
}

/// Real-time product list with local search + filter.
class ProductsCubit extends Cubit<ProductsState> with SafeEmit {
  final WatchProductsUseCase _watchProducts;
  StreamSubscription<List<ProductEntity>>? _sub;
  bool _activeOnly = true;

  ProductsCubit(this._watchProducts) : super(const ProductsState());

  void watch({required bool activeOnly}) {
    _activeOnly = activeOnly;
    _sub?.cancel();
    safeEmit(state.copyWith(status: LoadStatus.loading));
    _sub = _watchProducts(activeOnly).listen(
      (list) => safeEmit(state.copyWith(status: LoadStatus.loaded, products: list)),
      onError: (Object e) => safeEmit(state.copyWith(status: LoadStatus.error, error: e.toString())),
    );
  }

  void retry() => watch(activeOnly: _activeOnly);

  void search(String query) => safeEmit(state.copyWith(query: query, error: state.error));

  void setFilter(ProductFilter filter) =>
      safeEmit(state.copyWith(filter: filter, error: state.error));

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
