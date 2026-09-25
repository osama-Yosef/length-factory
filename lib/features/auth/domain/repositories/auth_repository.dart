import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  /// Live session: re-emits whenever auth state OR the profile doc changes
  /// (e.g. the customer's balance after checkout / payment).
  Stream<AuthSession> watchSession();

  Future<Either<Failure, Unit>> signIn({required String email, required String password});

  Future<Either<Failure, Unit>> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> sendPasswordReset(String email);

  Future<Either<Failure, Unit>> signOut();
}
