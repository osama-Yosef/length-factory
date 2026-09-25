import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/payment_entity.dart';

abstract class AccountsRepository {
  Stream<List<UserEntity>> watchCustomers();
  Stream<List<UserEntity>> watchStaff();
  Stream<List<PaymentEntity>> watchPayments(String customerId);

  /// Records a payment and decreases the customer's balance atomically.
  Future<Either<Failure, Unit>> recordPayment({
    required String customerId,
    required double amount,
    required String adminId,
    required String adminName,
    String? notes,
  });

  Future<Either<Failure, Unit>> setUserActive(String uid, bool isActive);

  /// Creates a Firebase Auth account + profile for a Worker / Admin
  /// without signing the current admin out.
  Future<Either<Failure, Unit>> createStaffAccount({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  });

  Future<Either<Failure, Unit>> updateProfile({
    required String uid,
    required String name,
    required String phone,
  });
}
