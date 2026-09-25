import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/product_entity.dart';

/// Immutable cart line.
class CartItem extends Equatable {
  final ProductEntity product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  double get lineTotal => product.price * quantity;

  CartItem copyWith({ProductEntity? product, int? quantity}) =>
      CartItem(product: product ?? this.product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}
