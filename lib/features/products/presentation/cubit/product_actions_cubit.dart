import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/safe_emit.dart';
import '../../../../core/cubit/submission_state.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/product_usecases.dart';

/// Admin product mutations: add / edit / hide / restore.
class ProductActionsCubit extends Cubit<SubmissionState> with SafeEmit {
  final AddProductUseCase _add;
  final UpdateProductUseCase _update;
  final SetProductActiveUseCase _setActive;

  ProductActionsCubit(this._add, this._update, this._setActive)
      : super(const SubmissionInitial());

  Future<void> add(ProductDraft draft) async {
    safeEmit(const SubmissionLoading());
    final r = await _add(draft);
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess('تمت إضافة المنتج بنجاح')),
    );
  }

  Future<void> update(ProductEntity product, {String? newImagePath}) async {
    safeEmit(const SubmissionLoading());
    final r = await _update(UpdateProductParams(product, newImagePath: newImagePath));
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess('تم حفظ التعديلات')),
    );
  }

  Future<void> setActive(ProductEntity product, bool isActive) async {
    safeEmit(const SubmissionLoading());
    final r = await _setActive(SetProductActiveParams(product.id, isActive));
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess(
            isActive ? 'تمت إعادة عرض "${product.name}"' : 'تم إخفاء "${product.name}" من المتجر',
          )),
    );
  }
}
