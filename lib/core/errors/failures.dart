import 'package:equatable/equatable.dart';

/// Domain-level error returned inside `Left` of an `Either`.
///
/// Cubits only ever deal with [Failure]s and show [message] to the user.
abstract class Failure extends Equatable implements Exception {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'حدث خطأ غير متوقع، حاول مرة أخرى']);
}
