import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  AuthRepositoryImpl(this._remote);

  @override
  Stream<AuthSession> watchSession() => guardStream(_remote.watchSession());

  @override
  Future<Either<Failure, Unit>> signIn({required String email, required String password}) =>
      guard(() async {
        await _remote.signIn(email: email, password: password);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) =>
      guard(() async {
        await _remote.registerCustomer(name: name, phone: phone, email: email, password: password);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> sendPasswordReset(String email) => guard(() async {
        await _remote.sendPasswordReset(email);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> signOut() => guard(() async {
        await _remote.signOut();
        return unit;
      });
}
