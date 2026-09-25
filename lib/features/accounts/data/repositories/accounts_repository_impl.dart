import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../datasources/accounts_remote_data_source.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  final AccountsRemoteDataSource _remote;

  AccountsRepositoryImpl(this._remote);

  @override
  Stream<List<UserEntity>> watchCustomers() => guardStream(_remote.watchCustomers());

  @override
  Stream<List<UserEntity>> watchStaff() => guardStream(_remote.watchStaff());

  @override
  Stream<List<PaymentEntity>> watchPayments(String customerId) =>
      guardStream(_remote.watchPayments(customerId));

  @override
  Future<Either<Failure, Unit>> recordPayment({
    required String customerId,
    required double amount,
    required String adminId,
    required String adminName,
    String? notes,
  }) =>
      guard(() async {
        await _remote.recordPayment(
          customerId: customerId,
          amount: amount,
          adminId: adminId,
          adminName: adminName,
          notes: notes,
        );
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> setUserActive(String uid, bool isActive) => guard(() async {
        await _remote.setUserActive(uid, isActive);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> createStaffAccount({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) =>
      guard(() async {
        await _remote.createStaffAccount(
          name: name,
          phone: phone,
          email: email,
          password: password,
          role: role,
        );
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) =>
      guard(() async {
        await _remote.updateProfile(uid: uid, name: name, phone: phone);
        return unit;
      });
}
