import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;

  /// One-off message to show on the login screen (e.g. account disabled).
  final String? message;

  const AuthState._({required this.status, this.user, this.message});

  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.authenticated(UserEntity user)
      : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated([String? message])
      : this._(status: AuthStatus.unauthenticated, message: message);

  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  List<Object?> get props => [status, user, message];
}
