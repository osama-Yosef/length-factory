import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remote;

  ProductRepositoryImpl(this._remote);

  @override
  Stream<List<ProductEntity>> watchProducts({required bool activeOnly}) =>
      guardStream(_remote.watchProducts(activeOnly: activeOnly));

  @override
  Future<Either<Failure, Unit>> addProduct(ProductDraft draft) => guard(() async {
        await _remote.addProduct(draft);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> updateProduct(ProductEntity product, {String? newImagePath}) =>
      guard(() async {
        await _remote.updateProduct(ProductModel.fromEntity(product), newImagePath: newImagePath);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> setProductActive(String productId, bool isActive) =>
      guard(() async {
        await _remote.setActive(productId, isActive);
        return unit;
      });
}
