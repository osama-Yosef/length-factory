import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// A single line item inside an order — a *snapshot* of the product at
/// order time, so history stays correct even if the product changes.
class OrderItemEntity extends Equatable {
  final String productId;
  final String productName;
  final String productImage;
  final double unitPrice;
  final int quantity;

  const OrderItemEntity({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;

  @override
  List<Object?> get props => [productId, productName, unitPrice, quantity];
}

class OrderEntity extends Equatable {
  final String id;
  final String orderNumber; // short human-friendly number
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItemEntity> items;
  final double totalPrice;
  final String status; // OrderStatus
  final String paymentStatus; // PaymentStatus
  final String? workerNote; // visible to Admin & Worker only
  final String? customerNote; // optional note written at checkout
  final DateTime createdAt;
  final DateTime? completedAt;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalPrice,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.unpaid,
    this.workerNote,
    this.customerNote,
    required this.createdAt,
    this.completedAt,
  });

  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isPending => status == OrderStatus.pending;
  bool get isPreparing => status == OrderStatus.preparing;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isActive => isPending || isPreparing;
  bool get hasWorkerNote => workerNote != null && workerNote!.trim().isNotEmpty;
  bool get hasCustomerNote => customerNote != null && customerNote!.trim().isNotEmpty;

  /// Allowed next statuses from the current one.
  List<String> get nextStatuses => OrderStatusFlow.next(status);

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        customerId,
        items,
        totalPrice,
        status,
        paymentStatus,
        workerNote,
        customerNote,
        completedAt,
      ];
}

/// Business rules for order status transitions.
class OrderStatusFlow {
  OrderStatusFlow._();

  static List<String> next(String status) {
    switch (status) {
      case OrderStatus.pending:
        return const [OrderStatus.preparing, OrderStatus.cancelled];
      case OrderStatus.preparing:
        return const [OrderStatus.completed, OrderStatus.pending, OrderStatus.cancelled];
      default:
        return const [];
    }
  }

  static bool canMove(String from, String to) => next(from).contains(to);
}
