import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Stream<List<ProductEntity>> watchProducts({required bool activeOnly});

  Future<Either<Failure, Unit>> addProduct(ProductDraft draft);

  Future<Either<Failure, Unit>> updateProduct(ProductEntity product, {String? newImagePath});

  /// Soft-delete / restore — historical orders keep referencing the product.
  Future<Either<Failure, Unit>> setProductActive(String productId, bool isActive);
}
