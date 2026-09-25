import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/safe_emit.dart';
import '../../../../core/cubit/submission_state.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/accounts_usecases.dart';

/// Account mutations: payments, (de)activation, staff creation, profile edit.
class AccountActionsCubit extends Cubit<SubmissionState> with SafeEmit {
  final RecordPaymentUseCase _recordPayment;
  final SetUserActiveUseCase _setActive;
  final CreateStaffAccountUseCase _createStaff;
  final UpdateProfileUseCase _updateProfile;

  AccountActionsCubit(
    this._recordPayment,
    this._setActive,
    this._createStaff,
    this._updateProfile,
  ) : super(const SubmissionInitial());

  Future<void> recordPayment({
    required UserEntity customer,
    required UserEntity admin,
    required double amount,
    String? notes,
  }) async {
    safeEmit(const SubmissionLoading());
    final r = await _recordPayment(
      RecordPaymentParams(customer: customer, amount: amount, admin: admin, notes: notes),
    );
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess('تم تسجيل دفعة ${FormatUtils.currency(amount)} بنجاح')),
    );
  }

  Future<void> setActive(UserEntity user, bool isActive) async {
    safeEmit(const SubmissionLoading());
    final r = await _setActive(SetUserActiveParams(user.uid, isActive));
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess(
            isActive ? 'تم تفعيل حساب ${user.name}' : 'تم إيقاف حساب ${user.name}',
          )),
    );
  }

  Future<void> createStaff(CreateStaffParams params) async {
    safeEmit(const SubmissionLoading());
    final r = await _createStaff(params);
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess(
            'تم إنشاء حساب ${FormatUtils.role(params.role)}: ${params.name}',
          )),
    );
  }

  Future<void> updateProfile(UpdateProfileParams params) async {
    safeEmit(const SubmissionLoading());
    final r = await _updateProfile(params);
    r.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess('تم تحديث البيانات')),
    );
  }
}
