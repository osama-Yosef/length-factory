import 'package:equatable/equatable.dart';

import 'user_entity.dart';

/// What the app knows about the signed-in user at any moment.
sealed class AuthSession extends Equatable {
  const AuthSession();

  @override
  List<Object?> get props => [];
}

/// Nobody is signed in.
class SignedOutSession extends AuthSession {
  const SignedOutSession();
}

/// Firebase Auth has a user but the Firestore profile doesn't exist (yet).
/// Happens briefly right after registration.
class ProfilePendingSession extends AuthSession {
  final String uid;
  const ProfilePendingSession(this.uid);

  @override
  List<Object?> get props => [uid];
}

/// Signed in with a loaded (and live-updating) profile.
class ActiveSession extends AuthSession {
  final UserEntity user;
  const ActiveSession(this.user);

  @override
  List<Object?> get props => [user];
}
