import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class WatchProductsUseCase extends StreamUseCase<List<ProductEntity>, bool> {
  final ProductRepository _repo;
  WatchProductsUseCase(this._repo);

  /// [activeOnly] — `true` for the storefront, `false` for admin management.
  @override
  Stream<List<ProductEntity>> call(bool activeOnly) =>
      _repo.watchProducts(activeOnly: activeOnly);
}

Failure? _validate(String name, double price, int quantity) {
  if (name.trim().isEmpty) return const ValidationFailure('اسم المنتج مطلوب');
  if (price <= 0) return const ValidationFailure('السعر يجب أن يكون أكبر من صفر');
  if (quantity < 0) return const ValidationFailure('الكمية لا يمكن أن تكون سالبة');
  return null;
}

class AddProductUseCase extends UseCase<Unit, ProductDraft> {
  final ProductRepository _repo;
  AddProductUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(ProductDraft draft) async {
    final error = _validate(draft.name, draft.price, draft.quantity);
    if (error != null) return Left(error);
    return _repo.addProduct(draft);
  }
}

class UpdateProductParams extends Equatable {
  final ProductEntity product;
  final String? newImagePath;
  const UpdateProductParams(this.product, {this.newImagePath});

  @override
  List<Object?> get props => [product, newImagePath];
}

class UpdateProductUseCase extends UseCase<Unit, UpdateProductParams> {
  final ProductRepository _repo;
  UpdateProductUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(UpdateProductParams p) async {
    final error = _validate(p.product.name, p.product.price, p.product.quantity);
    if (error != null) return Left(error);
    return _repo.updateProduct(p.product, newImagePath: p.newImagePath);
  }
}

class SetProductActiveParams extends Equatable {
  final String productId;
  final bool isActive;
  const SetProductActiveParams(this.productId, this.isActive);

  @override
  List<Object?> get props => [productId, isActive];
}

class SetProductActiveUseCase extends UseCase<Unit, SetProductActiveParams> {
  final ProductRepository _repo;
  SetProductActiveUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(SetProductActiveParams p) =>
      _repo.setProductActive(p.productId, p.isActive);
}
