import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'auth_state.dart';

/// Global session Cubit — the single source of truth for "who is logged
/// in and what is their role". GoRouter listens to it for redirects.
class AuthCubit extends Cubit<AuthState> {
  final WatchSessionUseCase _watchSession;
  final SignOutUseCase _signOut;

  StreamSubscription<AuthSession>? _sub;
  Timer? _pendingTimer;

  AuthCubit(this._watchSession, this._signOut) : super(const AuthState.unknown()) {
    _sub = _watchSession(const NoParams()).listen(
      _onSession,
      onError: (_) => emit(const AuthState.unauthenticated()),
    );
  }

  void _onSession(AuthSession session) {
    switch (session) {
      case SignedOutSession():
        _pendingTimer?.cancel();
        // Keep a pending message (e.g. "account disabled") visible.
        emit(AuthState.unauthenticated(state.message));
      case ProfilePendingSession():
        emit(const AuthState.unknown());
        _pendingTimer?.cancel();
        _pendingTimer = Timer(AppConstants.profileLoadTimeout, () {
          _forceSignOut('بيانات الحساب غير مكتملة، تواصل مع الإدارة');
        });
      case ActiveSession(:final user):
        _pendingTimer?.cancel();
        if (!user.isActive) {
          _forceSignOut('تم إيقاف هذا الحساب، تواصل مع الإدارة');
          return;
        }
        emit(AuthState.authenticated(user));
    }
  }

  Future<void> _forceSignOut(String message) async {
    emit(AuthState.unauthenticated(message));
    await _signOut(const NoParams());
  }

  Future<void> signOut() async {
    emit(const AuthState.unauthenticated());
    await _signOut(const NoParams());
  }

  /// Called by the login screen once the message has been shown.
  void clearMessage() {
    if (state.message != null && state.status == AuthStatus.unauthenticated) {
      emit(const AuthState.unauthenticated());
    }
  }

  @override
  Future<void> close() async {
    _pendingTimer?.cancel();
    await _sub?.cancel();
    return super.close();
  }
}
