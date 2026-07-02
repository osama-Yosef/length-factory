import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.customerId,
    required super.amount,
    required super.date,
    required super.adminId,
    required super.adminName,
    super.notes,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PaymentModel(
      id: documentId,
      customerId: map['customerId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminId: map['adminId'] as String? ?? '',
      adminName: map['adminName'] as String? ?? '',
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'adminId': adminId,
      'adminName': adminName,
      'notes': notes,
    };
  }
}
