import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String description;
  final int quantity; // available stock
  final DateTime createdAt;
  final bool isActive;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.description = '',
    required this.quantity,
    required this.createdAt,
    this.isActive = true,
  });

  bool get isOutOfStock => quantity <= 0;

  @override
  List<Object?> get props =>
      [id, name, imageUrl, price, description, quantity, isActive];
}
