import 'package:length_factory/features/auth/domain/entities/user_entity.dart';
import 'package:length_factory/features/orders/domain/entities/order_entity.dart';
import 'package:length_factory/features/products/domain/entities/product_entity.dart';

ProductEntity product({
  String id = 'p1',
  String name = 'لوح خشب',
  double price = 100,
  int quantity = 10,
  bool isActive = true,
}) =>
    ProductEntity(
      id: id,
      name: name,
      imageUrl: '',
      price: price,
      quantity: quantity,
      isActive: isActive,
      createdAt: DateTime(2026, 1, 1),
    );

UserEntity user({
  String uid = 'u1',
  String role = 'customer',
  double balance = 0,
  bool isActive = true,
}) =>
    UserEntity(
      uid: uid,
      name: 'أحمد',
      phone: '01012345678',
      email: 'a@b.com',
      role: role,
      balance: balance,
      isActive: isActive,
      createdAt: DateTime(2026, 1, 1),
    );

OrderEntity order({
  String id = 'o1',
  String status = 'pending',
  double total = 200,
  DateTime? createdAt,
  String customerId = 'u1',
}) =>
    OrderEntity(
      id: id,
      orderNumber: 'ABC123',
      customerId: customerId,
      customerName: 'أحمد',
      customerPhone: '01012345678',
      items: [
        OrderItemEntity(
          productId: 'p1',
          productName: 'لوح خشب',
          productImage: '',
          unitPrice: total / 2,
          quantity: 2,
        ),
      ],
      totalPrice: total,
      status: status,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
    );
