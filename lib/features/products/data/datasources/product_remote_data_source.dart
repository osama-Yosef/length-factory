import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../domain/entities/product_entity.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Stream<List<ProductModel>> watchProducts({required bool activeOnly});
  Future<void> addProduct(ProductDraft draft);
  Future<void> updateProduct(ProductModel product, {String? newImagePath});
  Future<void> setActive(String productId, bool isActive);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore _firestore;
  final ImageUploadService _uploader;

  ProductRemoteDataSourceImpl(this._firestore, this._uploader);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.products);

  @override
  Stream<List<ProductModel>> watchProducts({required bool activeOnly}) {
    Query<Map<String, dynamic>> query = _col;
    if (activeOnly) query = query.where('isActive', isEqualTo: true);
    query = query.orderBy('createdAt', descending: true);
    return query.snapshots().map(
          (s) => s.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  @override
  Future<void> addProduct(ProductDraft draft) async {
    var imageUrl = '';
    if (draft.imagePath != null) {
      imageUrl = await _uploader.uploadImage(filePath: draft.imagePath!, folder: 'products');
    }
    final model = ProductModel(
      id: '',
      name: draft.name.trim(),
      imageUrl: imageUrl,
      price: draft.price,
      description: draft.description.trim(),
      quantity: draft.quantity,
      createdAt: DateTime.now(),
    );
    await _col.add(model.toMap());
  }

  @override
  Future<void> updateProduct(ProductModel product, {String? newImagePath}) async {
    var imageUrl = product.imageUrl;
    if (newImagePath != null) {
      imageUrl = await _uploader.uploadImage(filePath: newImagePath, folder: 'products');
    }
    final updated = ProductModel.fromEntity(product.copyWith(imageUrl: imageUrl));
    final map = updated.toMap()..remove('createdAt');
    await _col.doc(product.id).update(map);
  }

  @override
  Future<void> setActive(String productId, bool isActive) =>
      _col.doc(productId).update({'isActive': isActive});
}
