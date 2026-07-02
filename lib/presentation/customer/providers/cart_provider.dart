import 'package:flutter/foundation.dart';
import '../../../domain/entities/product_entity.dart';

class CartItem {
  final ProductEntity product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get lineTotal => product.price * quantity;
}

/// Holds the customer's in-progress cart before checkout.
///
/// Lives entirely in memory (Provider scoped to the Customer shell) —
/// cleared automatically after a successful checkout or logout.
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;

  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.values.fold(0, (sum, item) => sum + item.lineTotal);

  void addProduct(ProductEntity product) {
    if (_items.containsKey(product.id)) {
      _increment(product.id);
      return;
    }
    _items[product.id] = CartItem(product: product, quantity: 1);
    notifyListeners();
  }

  void _increment(String productId) {
    final item = _items[productId];
    if (item == null) return;
    if (item.quantity < item.product.quantity) {
      item.quantity++;
      notifyListeners();
    }
  }

  void increment(String productId) => _increment(productId);

  void decrement(String productId) {
    final item = _items[productId];
    if (item == null) return;
    if (item.quantity <= 1) {
      removeProduct(productId);
      return;
    }
    item.quantity--;
    notifyListeners();
  }

  void removeProduct(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
