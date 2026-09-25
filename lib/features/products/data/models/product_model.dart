import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    required super.price,
    super.description,
    required super.quantity,
    required super.createdAt,
    super.isActive,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      name: map['name'] as String? ?? '',
      imageUrl: map['image'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  factory ProductModel.fromEntity(ProductEntity e) => ProductModel(
        id: e.id,
        name: e.name,
        imageUrl: e.imageUrl,
        price: e.price,
        description: e.description,
        quantity: e.quantity,
        createdAt: e.createdAt,
        isActive: e.isActive,
      );

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': imageUrl,
      'price': price,
      'description': description,
      'quantity': quantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      // Lowercase copy used for simple prefix search queries in Firestore.
      'nameLower': name.toLowerCase(),
    };
  }
}
