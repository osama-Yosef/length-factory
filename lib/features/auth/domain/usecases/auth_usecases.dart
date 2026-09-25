import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class WatchSessionUseCase extends StreamUseCase<AuthSession, NoParams> {
  final AuthRepository _repo;
  WatchSessionUseCase(this._repo);

  @override
  Stream<AuthSession> call(NoParams params) => _repo.watchSession();
}

class SignInParams extends Equatable {
  final String email;
  final String password;
  const SignInParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email];
}

class SignInUseCase extends UseCase<Unit, SignInParams> {
  final AuthRepository _repo;
  SignInUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(SignInParams p) =>
      _repo.signIn(email: p.email.trim(), password: p.password);
}

class RegisterParams extends Equatable {
  final String name;
  final String phone;
  final String email;
  final String password;

  const RegisterParams({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, phone, email];
}

class RegisterCustomerUseCase extends UseCase<Unit, RegisterParams> {
  final AuthRepository _repo;
  RegisterCustomerUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(RegisterParams p) => _repo.registerCustomer(
        name: p.name.trim(),
        phone: p.phone.trim(),
        email: p.email.trim(),
        password: p.password,
      );
}

class SendPasswordResetUseCase extends UseCase<Unit, String> {
  final AuthRepository _repo;
  SendPasswordResetUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(String email) async {
    if (email.trim().isEmpty) {
      return const Left(ValidationFailure('أدخل البريد الإلكتروني أولًا'));
    }
    return _repo.sendPasswordReset(email.trim());
  }
}

class SignOutUseCase extends UseCase<Unit, NoParams> {
  final AuthRepository _repo;
  SignOutUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repo.signOut();
}
