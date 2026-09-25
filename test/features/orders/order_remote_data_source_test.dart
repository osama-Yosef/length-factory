import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:length_factory/core/errors/exceptions.dart';
import 'package:length_factory/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:length_factory/features/orders/data/models/order_model.dart';
import 'package:length_factory/features/orders/domain/entities/order_entity.dart';

void main() {
  late FakeFirebaseFirestore db;
  late OrderRemoteDataSourceImpl ds;

  Future<void> seed({int stock = 10, double balance = 0}) async {
    await db.collection('users').doc('u1').set({
      'name': 'أحمد',
      'role': 'customer',
      'balance': balance,
      'createdAt': Timestamp.now(),
    });
    await db.collection('products').doc('p1').set({
      'name': 'لوح',
      'price': 100,
      'quantity': stock,
      'isActive': true,
      'createdAt': Timestamp.now(),
    });
  }

  OrderModel newOrder({int qty = 3}) => OrderModel(
        id: '',
        orderNumber: 'N1',
        customerId: 'u1',
        customerName: 'أحمد',
        customerPhone: '010',
        items: [
          OrderItemEntity(
            productId: 'p1',
            productName: 'لوح',
            productImage: '',
            unitPrice: 100,
            quantity: qty,
          ),
        ],
        totalPrice: 100.0 * qty,
        createdAt: DateTime.now(),
      );

  Future<num> balance() async => (await db.collection('users').doc('u1').get()).data()!['balance'] as num;
  Future<num> stock() async => (await db.collection('products').doc('p1').get()).data()!['quantity'] as num;

  setUp(() {
    db = FakeFirebaseFirestore();
    ds = OrderRemoteDataSourceImpl(db);
  });

  test('placeOrder creates the order, raises balance and decrements stock', () async {
    await seed(stock: 10, balance: 50);

    final placed = await ds.placeOrder(newOrder(qty: 3));

    expect(placed.id, isNotEmpty);
    expect(await balance(), 350);
    expect(await stock(), 7);
    final saved = await db.collection('orders').doc(placed.id).get();
    expect(saved.data()!['status'], 'pending');
  });

  test('placeOrder fails when stock is insufficient and changes nothing', () async {
    await seed(stock: 2);

    await expectLater(ds.placeOrder(newOrder(qty: 3)), throwsA(isA<FirestoreException>()));
    expect(await stock(), 2);
    expect(await balance(), 0);
    expect((await db.collection('orders').get()).docs, isEmpty);
  });

  test('cancelling reverses balance and restores stock', () async {
    await seed(stock: 10);
    final placed = await ds.placeOrder(newOrder(qty: 4));

    await ds.updateStatus(placed.id, 'cancelled');

    expect(await balance(), 0);
    expect(await stock(), 10);
    final o = await db.collection('orders').doc(placed.id).get();
    expect(o.data()!['status'], 'cancelled');
  });

  test('completing sets completedAt; a cancelled order cannot change', () async {
    await seed();
    final placed = await ds.placeOrder(newOrder());

    await ds.updateStatus(placed.id, 'preparing');
    await ds.updateStatus(placed.id, 'completed');
    final o = await db.collection('orders').doc(placed.id).get();
    expect(o.data()!['completedAt'], isNotNull);

    final other = await ds.placeOrder(newOrder(qty: 1));
    await ds.updateStatus(other.id, 'cancelled');
    await expectLater(ds.updateStatus(other.id, 'pending'), throwsA(isA<FirestoreException>()));
  });

  test('deleting a non-cancelled order reverses its effects', () async {
    await seed(stock: 10);
    final placed = await ds.placeOrder(newOrder(qty: 2));

    await ds.deleteOrder(placed.id);

    expect(await balance(), 0);
    expect(await stock(), 10);
    expect((await db.collection('orders').doc(placed.id).get()).exists, isFalse);
  });

  test('watchCustomerOrders only returns that customer\'s orders', () async {
    await seed();
    await ds.placeOrder(newOrder(qty: 1));
    await db.collection('orders').add({
      ...newOrder().toMap(),
      'customerId': 'someone-else',
    });

    final list = await ds.watchCustomerOrders('u1').first;
    expect(list.length, 1);
    expect(list.single.customerId, 'u1');
  });
}
