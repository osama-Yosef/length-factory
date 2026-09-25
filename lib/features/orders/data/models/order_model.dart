import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/order_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.productId,
    required super.productName,
    required super.productImage,
    required super.unitPrice,
    required super.quantity,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      productImage: map['productImage'] as String? ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  factory OrderItemModel.fromEntity(OrderItemEntity e) => OrderItemModel(
        productId: e.productId,
        productName: e.productName,
        productImage: e.productImage,
        unitPrice: e.unitPrice,
        quantity: e.quantity,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.customerId,
    required super.customerName,
    required super.customerPhone,
    required super.items,
    required super.totalPrice,
    super.status,
    super.paymentStatus,
    super.workerNote,
    super.customerNote,
    required super.createdAt,
    super.completedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    final items = (map['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return OrderModel(
      id: documentId,
      orderNumber: map['orderNumber'] as String? ??
          (documentId.length >= 6 ? documentId.substring(0, 6) : documentId),
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['phone'] as String? ?? '',
      items: items,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? OrderStatus.pending,
      paymentStatus: map['paymentStatus'] as String? ?? PaymentStatus.unpaid,
      workerNote: map['workerNote'] as String?,
      customerNote: map['customerNote'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory OrderModel.fromEntity(OrderEntity e, {String? id}) => OrderModel(
        id: id ?? e.id,
        orderNumber: e.orderNumber,
        customerId: e.customerId,
        customerName: e.customerName,
        customerPhone: e.customerPhone,
        items: e.items,
        totalPrice: e.totalPrice,
        status: e.status,
        paymentStatus: e.paymentStatus,
        workerNote: e.workerNote,
        customerNote: e.customerNote,
        createdAt: e.createdAt,
        completedAt: e.completedAt,
      );

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'phone': customerPhone,
      'items': items.map((e) => OrderItemModel.fromEntity(e).toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'paymentStatus': paymentStatus,
      'workerNote': workerNote,
      'customerNote': customerNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
