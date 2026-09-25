import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Stream<List<OrderModel>> watchAllOrders();
  Stream<List<OrderModel>> watchCustomerOrders(String customerId);
  Stream<List<OrderModel>> watchWorkerQueue();
  Future<OrderModel> placeOrder(OrderModel order);
  Future<void> updateStatus(String orderId, String newStatus);
  Future<void> updatePaymentStatus(String orderId, String paymentStatus);
  Future<void> setWorkerNote(String orderId, String note);
  Future<void> deleteOrder(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final FirebaseFirestore _firestore;

  OrderRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestoreCollections.orders);
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  List<OrderModel> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();

  // ─────────────────────────── Streams ───────────────────────────

  @override
  Stream<List<OrderModel>> watchAllOrders() =>
      _orders.orderBy('createdAt', descending: true).snapshots().map(_map);

  @override
  Stream<List<OrderModel>> watchCustomerOrders(String customerId) => _orders
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_map);

  /// FIFO production queue (pending + preparing).
  @override
  Stream<List<OrderModel>> watchWorkerQueue() => _orders
      .where('status', whereIn: OrderStatus.activeForWorker)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map(_map);

  // ─────────────────────────── Checkout ───────────────────────────
  //
  // Atomically:
  //   1. validate stock for every item,
  //   2. create the order,
  //   3. increase the customer's outstanding balance,
  //   4. decrement stock.
  // A single transaction guarantees we never end up half-applied.
  @override
  Future<OrderModel> placeOrder(OrderModel order) {
    return _firestore.runTransaction<OrderModel>((txn) async {
      // Reads first (Firestore requires all reads before writes).
      final stock = <String, int>{};
      for (final item in order.items) {
        final snap = await txn.get(_products.doc(item.productId));
        final data = snap.data();
        if (!snap.exists || data == null || (data['isActive'] as bool? ?? true) == false) {
          throw FirestoreException('المنتج "${item.productName}" لم يعد متاحًا');
        }
        final available = (data['quantity'] as num?)?.toInt() ?? 0;
        final alreadyRequested = order.items
            .where((i) => i.productId == item.productId)
            .fold<int>(0, (s, i) => s + i.quantity);
        if (available < alreadyRequested) {
          throw FirestoreException(
            'الكمية المتاحة من "${item.productName}" غير كافية (المتاح: $available)',
          );
        }
        stock[item.productId] = available;
      }

      final customerRef = _users.doc(order.customerId);
      final customerSnap = await txn.get(customerRef);
      if (!customerSnap.exists) throw const FirestoreException('حساب العميل غير موجود');
      final balance = (customerSnap.data()?['balance'] as num?)?.toDouble() ?? 0;

      // Writes
      final orderRef = _orders.doc();
      txn.set(orderRef, order.toMap());
      txn.update(customerRef, {'balance': balance + order.totalPrice});
      final requested = <String, int>{};
      for (final item in order.items) {
        requested[item.productId] = (requested[item.productId] ?? 0) + item.quantity;
      }
      requested.forEach((productId, qty) {
        txn.update(_products.doc(productId), {'quantity': stock[productId]! - qty});
      });

      return OrderModel.fromEntity(order, id: orderRef.id);
    });
  }

  // ─────────────────────────── Mutations ───────────────────────────

  @override
  Future<void> updateStatus(String orderId, String newStatus) {
    return _firestore.runTransaction((txn) async {
      final ref = _orders.doc(orderId);
      final snap = await txn.get(ref);
      if (!snap.exists) throw const FirestoreException('الطلب غير موجود');
      final order = OrderModel.fromMap(snap.data()!, snap.id);

      if (order.status == newStatus) return;
      if (order.isCancelled) throw const FirestoreException('لا يمكن تعديل طلب ملغي');

      if (newStatus == OrderStatus.cancelled) {
        await _reverseOrderEffects(txn, order);
        txn.update(ref, {'status': OrderStatus.cancelled});
        return;
      }

      txn.update(ref, {
        'status': newStatus,
        if (newStatus == OrderStatus.completed) 'completedAt': Timestamp.now(),
      });
    });
  }

  @override
  Future<void> deleteOrder(String orderId) {
    return _firestore.runTransaction((txn) async {
      final ref = _orders.doc(orderId);
      final snap = await txn.get(ref);
      if (!snap.exists) return;
      final order = OrderModel.fromMap(snap.data()!, snap.id);
      if (!order.isCancelled) await _reverseOrderEffects(txn, order);
      txn.delete(ref);
    });
  }

  /// Reads everything first, then: balance -= total, stock += quantities.
  /// Products that no longer exist are skipped.
  Future<void> _reverseOrderEffects(Transaction txn, OrderModel order) async {
    final customerRef = _users.doc(order.customerId);
    final customerSnap = await txn.get(customerRef);

    final restock = <String, int>{};
    for (final item in order.items) {
      restock[item.productId] = (restock[item.productId] ?? 0) + item.quantity;
    }
    final productSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final id in restock.keys) {
      productSnaps[id] = await txn.get(_products.doc(id));
    }

    if (customerSnap.exists) {
      final balance = (customerSnap.data()?['balance'] as num?)?.toDouble() ?? 0;
      txn.update(customerRef, {'balance': balance - order.totalPrice});
    }
    restock.forEach((id, qty) {
      final snap = productSnaps[id]!;
      if (!snap.exists) return;
      final current = (snap.data()?['quantity'] as num?)?.toInt() ?? 0;
      txn.update(_products.doc(id), {'quantity': current + qty});
    });
  }

  @override
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) =>
      _orders.doc(orderId).update({'paymentStatus': paymentStatus});

  @override
  Future<void> setWorkerNote(String orderId, String note) =>
      _orders.doc(orderId).update({'workerNote': note.isEmpty ? null : note});
}
