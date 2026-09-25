import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';

/// Firestore mapping for [UserEntity].
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.phone,
    required super.email,
    required super.role,
    super.balance,
    required super.createdAt,
    super.isActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? UserRole.customer,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  factory UserModel.fromEntity(UserEntity e) => UserModel(
        uid: e.uid,
        name: e.name,
        phone: e.phone,
        email: e.email,
        role: e.role,
        balance: e.balance,
        createdAt: e.createdAt,
        isActive: e.isActive,
      );

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}
