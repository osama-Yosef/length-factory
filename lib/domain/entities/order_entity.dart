import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// A single line item inside an order (snapshot of product at order time).
///
/// Storing `productName` and `unitPrice` as a *snapshot* (instead of only
/// a `productId` reference) ensures historical orders remain accurate
/// even if the product is later edited, renamed or deleted by the Admin.
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
  final String orderNumber; // human-friendly sequential/short number
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItemEntity> items;
  final double totalPrice;
  final String status; // OrderStatus
  final String paymentStatus; // PaymentStatus
  final String? workerNote; // visible to Admin only
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
    required this.createdAt,
    this.completedAt,
  });

  int get totalItemsCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props =>
      [id, orderNumber, customerId, totalPrice, status, paymentStatus];
}
