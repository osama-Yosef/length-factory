import 'package:equatable/equatable.dart';

/// A payment made by a customer toward their outstanding balance.
class PaymentEntity extends Equatable {
  final String id;
  final String customerId;
  final double amount;
  final DateTime date;
  final String adminId;
  final String adminName;
  final String? notes;

  const PaymentEntity({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    required this.adminId,
    required this.adminName,
    this.notes,
  });

  @override
  List<Object?> get props => [id, customerId, amount, date, adminId, notes];
}
