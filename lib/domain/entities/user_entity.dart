import 'package:equatable/equatable.dart';

/// Pure domain representation of an application user.
///
/// This class intentionally has **no** Firebase imports — the Domain
/// layer must stay framework-agnostic. Conversion to/from Firestore
/// happens in [UserModel] (data layer), which extends this entity.
class UserEntity extends Equatable {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String role; // admin | customer | worker
  final double balance; // only meaningful for role == customer
  final DateTime createdAt;
  final bool isActive;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.balance = 0,
    required this.createdAt,
    this.isActive = true,
  });

  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';
  bool get isWorker => role == 'worker';

  @override
  List<Object?> get props => [uid, name, phone, email, role, balance, isActive];
}
