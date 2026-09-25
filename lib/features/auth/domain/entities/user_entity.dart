import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// Pure domain representation of an application user (no Firebase imports).
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

  bool get isAdmin => role == UserRole.admin;
  bool get isCustomer => role == UserRole.customer;
  bool get isWorker => role == UserRole.worker;

  /// First letter used for avatars.
  String get initial => name.trim().isNotEmpty ? name.trim()[0] : '?';

  @override
  List<Object?> get props => [uid, name, phone, email, role, balance, isActive];
}
