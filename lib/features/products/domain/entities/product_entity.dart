import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

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
  bool get isLowStock => !isOutOfStock && quantity <= AppConstants.lowStockThreshold;

  ProductEntity copyWith({
    String? name,
    String? imageUrl,
    double? price,
    String? description,
    int? quantity,
    bool? isActive,
  }) {
    return ProductEntity(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, imageUrl, price, description, quantity, isActive];
}

/// Input for creating a new product (no id yet).
class ProductDraft extends Equatable {
  final String name;
  final double price;
  final String description;
  final int quantity;

  /// Local file path of a picked image (uploaded by the data layer).
  final String? imagePath;

  const ProductDraft({
    required this.name,
    required this.price,
    required this.description,
    required this.quantity,
    this.imagePath,
  });

  @override
  List<Object?> get props => [name, price, description, quantity, imagePath];
}
