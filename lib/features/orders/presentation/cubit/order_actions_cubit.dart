import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/cubit/safe_emit.dart';
import '../../../../core/cubit/submission_state.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/order_usecases.dart';

/// Order mutations used by the Admin and Worker screens.
class OrderActionsCubit extends Cubit<SubmissionState> with SafeEmit {
  final UpdateOrderStatusUseCase _updateStatus;
  final UpdatePaymentStatusUseCase _updatePayment;
  final SetWorkerNoteUseCase _setNote;
  final DeleteOrderUseCase _delete;

  OrderActionsCubit(this._updateStatus, this._updatePayment, this._setNote, this._delete)
      : super(const SubmissionInitial());

  Future<void> changeStatus(OrderEntity order, String newStatus) async {
    safeEmit(const SubmissionLoading());
    final r = await _updateStatus(UpdateOrderStatusParams(order, newStatus));
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess(
            newStatus == OrderStatus.cancelled
                ? 'تم إلغاء الطلب #${order.orderNumber} وإرجاع الرصيد والمخزون'
                : 'حالة الطلب #${order.orderNumber}: ${FormatUtils.orderStatus(newStatus)}',
          )),
    );
  }

  Future<void> changePaymentStatus(OrderEntity order, String paymentStatus) async {
    safeEmit(const SubmissionLoading());
    final r = await _updatePayment(UpdatePaymentStatusParams(order.id, paymentStatus));
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess('حالة الدفع: ${FormatUtils.paymentStatus(paymentStatus)}')),
    );
  }

  Future<void> saveWorkerNote(OrderEntity order, String note) async {
    safeEmit(const SubmissionLoading());
    final r = await _setNote(SetWorkerNoteParams(order.id, note));
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess(note.trim().isEmpty ? 'تم حذف الملاحظة' : 'تم حفظ الملاحظة')),
    );
  }

  Future<void> delete(OrderEntity order) async {
    safeEmit(const SubmissionLoading());
    final r = await _delete(order.id);
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess('تم حذف الطلب #${order.orderNumber}')),
    );
  }
}
