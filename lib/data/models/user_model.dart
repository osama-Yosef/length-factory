import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// Data-layer representation of [UserEntity].
///
/// Handles conversion to/from Firestore documents. Keeping this
/// separate from [UserEntity] means the Domain layer never depends
/// on `cloud_firestore`.
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
      role: map['role'] as String? ?? 'customer',
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      role: entity.role,
      balance: entity.balance,
      createdAt: entity.createdAt,
      isActive: entity.isActive,
    );
  }

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

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? role,
    double? balance,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
