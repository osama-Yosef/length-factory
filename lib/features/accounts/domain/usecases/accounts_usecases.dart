import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/payment_entity.dart';
import '../repositories/accounts_repository.dart';

class WatchCustomersUseCase extends StreamUseCase<List<UserEntity>, NoParams> {
  final AccountsRepository _repo;
  WatchCustomersUseCase(this._repo);

  @override
  Stream<List<UserEntity>> call(NoParams params) => _repo.watchCustomers();
}

class WatchStaffUseCase extends StreamUseCase<List<UserEntity>, NoParams> {
  final AccountsRepository _repo;
  WatchStaffUseCase(this._repo);

  @override
  Stream<List<UserEntity>> call(NoParams params) => _repo.watchStaff();
}

class WatchPaymentsUseCase extends StreamUseCase<List<PaymentEntity>, String> {
  final AccountsRepository _repo;
  WatchPaymentsUseCase(this._repo);

  @override
  Stream<List<PaymentEntity>> call(String customerId) => _repo.watchPayments(customerId);
}

class RecordPaymentParams extends Equatable {
  final UserEntity customer;
  final double amount;
  final UserEntity admin;
  final String? notes;

  const RecordPaymentParams({
    required this.customer,
    required this.amount,
    required this.admin,
    this.notes,
  });

  @override
  List<Object?> get props => [customer.uid, amount, admin.uid, notes];
}

class RecordPaymentUseCase extends UseCase<Unit, RecordPaymentParams> {
  final AccountsRepository _repo;
  RecordPaymentUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(RecordPaymentParams p) async {
    if (p.amount <= 0) {
      return const Left(ValidationFailure('قيمة الدفعة يجب أن تكون أكبر من صفر'));
    }
    if (p.amount > p.customer.balance) {
      return const Left(ValidationFailure('قيمة الدفعة أكبر من الرصيد المستحق'));
    }
    final notes = p.notes?.trim();
    return _repo.recordPayment(
      customerId: p.customer.uid,
      amount: p.amount,
      adminId: p.admin.uid,
      adminName: p.admin.name,
      notes: (notes == null || notes.isEmpty) ? null : notes,
    );
  }
}

class SetUserActiveParams extends Equatable {
  final String uid;
  final bool isActive;
  const SetUserActiveParams(this.uid, this.isActive);

  @override
  List<Object?> get props => [uid, isActive];
}

class SetUserActiveUseCase extends UseCase<Unit, SetUserActiveParams> {
  final AccountsRepository _repo;
  SetUserActiveUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(SetUserActiveParams p) => _repo.setUserActive(p.uid, p.isActive);
}

class CreateStaffParams extends Equatable {
  final String name;
  final String phone;
  final String email;
  final String password;
  final String role;

  const CreateStaffParams({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [name, phone, email, role];
}

class CreateStaffAccountUseCase extends UseCase<Unit, CreateStaffParams> {
  final AccountsRepository _repo;
  CreateStaffAccountUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(CreateStaffParams p) async {
    if (!UserRole.staff.contains(p.role)) {
      return const Left(ValidationFailure('الدور يجب أن يكون عامل أو مدير'));
    }
    if (p.name.trim().isEmpty) return const Left(ValidationFailure('الاسم مطلوب'));
    if (p.password.length < AppConstants.minPasswordLength) {
      return const Left(ValidationFailure('كلمة المرور قصيرة جدًا'));
    }
    return _repo.createStaffAccount(
      name: p.name.trim(),
      phone: p.phone.trim(),
      email: p.email.trim(),
      password: p.password,
      role: p.role,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String uid;
  final String name;
  final String phone;
  const UpdateProfileParams({required this.uid, required this.name, required this.phone});

  @override
  List<Object?> get props => [uid, name, phone];
}

class UpdateProfileUseCase extends UseCase<Unit, UpdateProfileParams> {
  final AccountsRepository _repo;
  UpdateProfileUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(UpdateProfileParams p) async {
    if (p.name.trim().isEmpty) return const Left(ValidationFailure('الاسم مطلوب'));
    return _repo.updateProfile(uid: p.uid, name: p.name.trim(), phone: p.phone.trim());
  }
}
