import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }
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
    required super.createdAt,
    super.completedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawItems = (map['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return OrderModel(
      id: documentId,
      orderNumber: map['orderNumber'] as String? ?? documentId.substring(0, 6),
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['phone'] as String? ?? '',
      items: rawItems,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      paymentStatus: map['paymentStatus'] as String? ?? 'unpaid',
      workerNote: map['workerNote'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'phone': customerPhone,
      'items': items
          .map((e) => OrderItemModel(
                productId: e.productId,
                productName: e.productName,
                productImage: e.productImage,
                unitPrice: e.unitPrice,
                quantity: e.quantity,
              ).toMap())
          .toList(),
      'totalPrice': totalPrice,
      'status': status,
      'paymentStatus': paymentStatus,
      'workerNote': workerNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
