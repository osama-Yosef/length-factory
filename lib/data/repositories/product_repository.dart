import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/services/storage_service.dart';
import '../models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  ProductRepository({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.products);

  /// Live stream of active products, newest first.
  /// Used by both Admin (management list) and Customer (storefront).
  Stream<List<ProductModel>> watchProducts({bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _col.orderBy('createdAt', descending: true);
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => ProductModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<ProductModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.data()!, doc.id);
  }

  /// Creates a product, optionally uploading [imageFile] first.
  Future<void> createProduct({
    required String name,
    required double price,
    required String description,
    required int quantity,
    File? imageFile,
  }) async {
    try {
      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await _storageService.uploadImage(
          file: imageFile,
          folder: 'products',
        );
      }

      final product = ProductModel(
        id: '', // assigned by Firestore
        name: name.trim(),
        imageUrl: imageUrl,
        price: price,
        description: description.trim(),
        quantity: quantity,
        createdAt: DateTime.now(),
      );

      await _col.add(product.toMap());
    } on FirebaseException catch (e) {
      throw FirestoreException('فشل إضافة المنتج: ${e.message}', code: e.code);
    }
  }

  /// Updates a product. Pass [newImageFile] to replace the existing image
  /// (the old image is deleted from Storage to avoid orphaned files).
  Future<void> updateProduct({
    required ProductModel product,
    File? newImageFile,
  }) async {
    try {
      String imageUrl = product.imageUrl;

      if (newImageFile != null) {
        final newUrl = await _storageService.uploadImage(
          file: newImageFile,
          folder: 'products',
        );
        if (product.imageUrl.isNotEmpty) {
          await _storageService.deleteImage(product.imageUrl);
        }
        imageUrl = newUrl;
      }

      final updated = product.copyWith(imageUrl: imageUrl);
      await _col.doc(product.id).update(updated.toMap());
    } on FirebaseException catch (e) {
      throw FirestoreException('فشل تحديث المنتج: ${e.message}', code: e.code);
    }
  }

  /// Soft-delete: marks the product inactive instead of physically
  /// deleting it, so historical orders that reference it stay intact.
  Future<void> deleteProduct(ProductModel product) async {
    try {
      await _col.doc(product.id).update({'isActive': false});
    } on FirebaseException catch (e) {
      throw FirestoreException('فشل حذف المنتج: ${e.message}', code: e.code);
    }
  }

  /// Decrements stock after an order is placed. Run inside the order
  /// transaction in [OrderRepository] — exposed here for reuse/testing.
  Future<void> decrementStock(
    Transaction txn,
    String productId,
    int amount,
  ) async {
    final ref = _col.doc(productId);
    final snap = await txn.get(ref);
    final currentQty = (snap.data()?['quantity'] as num?)?.toInt() ?? 0;
    final newQty = (currentQty - amount).clamp(0, currentQty);
    txn.update(ref, {'quantity': newQty});
  }
}
