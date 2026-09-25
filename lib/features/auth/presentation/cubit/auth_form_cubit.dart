import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/safe_emit.dart';
import '../../../../core/cubit/submission_state.dart';
import '../../domain/usecases/auth_usecases.dart';

/// Handles the login / register / reset-password forms.
///
/// On success no navigation is needed: [AuthCubit] picks up the new
/// session and GoRouter redirects to the correct role home.
class AuthFormCubit extends Cubit<SubmissionState> with SafeEmit {
  final SignInUseCase _signIn;
  final RegisterCustomerUseCase _register;
  final SendPasswordResetUseCase _reset;

  AuthFormCubit(this._signIn, this._register, this._reset) : super(const SubmissionInitial());

  Future<void> signIn(String email, String password) async {
    safeEmit(const SubmissionLoading());
    final result = await _signIn(SignInParams(email: email, password: password));
    result.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess()),
    );
  }

  Future<void> register(RegisterParams params) async {
    safeEmit(const SubmissionLoading());
    final result = await _register(params);
    result.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess('تم إنشاء الحساب بنجاح')),
    );
  }

  Future<void> sendReset(String email) async {
    final result = await _reset(email);
    result.fold(
      (f) => safeEmit(SubmissionFailure(f.message)),
      (_) => safeEmit(SubmissionSuccess('تم إرسال رابط استعادة كلمة المرور إلى بريدك')),
    );
  }
}
