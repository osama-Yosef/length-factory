import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item.dart';

class CartState extends Equatable {
  /// Keyed by product id, insertion-ordered.
  final Map<String, CartItem> itemsById;

  const CartState([this.itemsById = const {}]);

  List<CartItem> get items => itemsById.values.toList();
  bool get isEmpty => itemsById.isEmpty;
  int get itemCount => itemsById.length;
  int get totalQuantity => itemsById.values.fold(0, (s, i) => s + i.quantity);
  double get totalPrice => itemsById.values.fold(0, (s, i) => s + i.lineTotal);

  int quantityOf(String productId) => itemsById[productId]?.quantity ?? 0;
  bool contains(String productId) => itemsById.containsKey(productId);

  @override
  List<Object?> get props => [itemsById];
}

/// In-memory shopping cart (global; cleared on checkout / sign-out).
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  Map<String, CartItem> get _copy => Map.of(state.itemsById);

  /// Adds [quantity] units, capped by available stock.
  /// Returns the quantity actually in the cart afterwards.
  int add(ProductEntity product, {int quantity = 1}) {
    if (product.isOutOfStock || quantity <= 0) return state.quantityOf(product.id);
    final items = _copy;
    final current = items[product.id]?.quantity ?? 0;
    final next = (current + quantity).clamp(1, product.quantity);
    items[product.id] = CartItem(product: product, quantity: next);
    emit(CartState(items));
    return next;
  }

  /// Sets an exact quantity (0 removes the line).
  void setQuantity(ProductEntity product, int quantity) {
    final items = _copy;
    if (quantity <= 0) {
      items.remove(product.id);
    } else {
      items[product.id] = CartItem(product: product, quantity: quantity.clamp(1, product.quantity));
    }
    emit(CartState(items));
  }

  void increment(String productId) {
    final item = state.itemsById[productId];
    if (item == null || item.quantity >= item.product.quantity) return;
    emit(CartState(_copy..[productId] = item.copyWith(quantity: item.quantity + 1)));
  }

  void decrement(String productId) {
    final item = state.itemsById[productId];
    if (item == null) return;
    if (item.quantity <= 1) {
      remove(productId);
      return;
    }
    emit(CartState(_copy..[productId] = item.copyWith(quantity: item.quantity - 1)));
  }

  void remove(String productId) => emit(CartState(_copy..remove(productId)));

  void clear() => emit(const CartState());

  /// Refreshes product snapshots (price/stock) from the live catalog and
  /// drops products that were hidden or ran out of stock.
  void syncWithCatalog(List<ProductEntity> catalog) {
    if (state.isEmpty) return;
    final byId = {for (final p in catalog) p.id: p};
    final items = <String, CartItem>{};
    for (final item in state.items) {
      final fresh = byId[item.product.id];
      if (fresh == null || !fresh.isActive || fresh.isOutOfStock) continue;
      items[fresh.id] = CartItem(product: fresh, quantity: item.quantity.clamp(1, fresh.quantity));
    }
    final next = CartState(items);
    if (next != state) emit(next);
  }
}
