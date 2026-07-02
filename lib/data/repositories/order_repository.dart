import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection(FirestoreCollections.orders);

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _firestore.collection(FirestoreCollections.products);

  // ---------------------------------------------------------------------
  // CHECKOUT — the most critical transaction in the whole app.
  // ---------------------------------------------------------------------
  //
  // Must atomically:
  //   1. Create the order document.
  //   2. Increase the customer's outstanding balance by the invoice total.
  //   3. Decrement stock for every purchased product.
  //
  // Wrapping all three in a single Firestore [runTransaction] guarantees
  // we never end up with "order created but balance not updated" (or
  // vice-versa) even under concurrent checkouts / network retries.
  Future<String> placeOrder(OrderModel order) async {
    try {
      return await _firestore.runTransaction<String>((txn) async {
        // --- 1. Validate stock for every item first (reads must happen
        // before any writes in a Firestore transaction). ---
        final productSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final item in order.items) {
          final ref = _productsCol.doc(item.productId);
          final snap = await txn.get(ref);
          if (!snap.exists) {
            throw FirestoreException('المنتج "${item.productName}" لم يعد متاحًا');
          }
          final available = (snap.data()?['quantity'] as num?)?.toInt() ?? 0;
          if (available < item.quantity) {
            throw FirestoreException(
              'الكمية المتاحة من "${item.productName}" غير كافية (متاح: $available)',
            );
          }
          productSnapshots[item.productId] = snap;
        }

        final customerRef = _usersCol.doc(order.customerId);
        final customerSnap = await txn.get(customerRef);
        final currentBalance =
            (customerSnap.data()?['balance'] as num?)?.toDouble() ?? 0;

        // --- 2. Write: create order ---
        final orderRef = _ordersCol.doc();
        txn.set(orderRef, order.toMap());

        // --- 3. Write: increase customer balance ---
        txn.update(customerRef, {
          'balance': currentBalance + order.totalPrice,
        });

        // --- 4. Write: decrement stock per product ---
        for (final item in order.items) {
          final ref = _productsCol.doc(item.productId);
          final currentQty =
              (productSnapshots[item.productId]!.data()?['quantity'] as num?)
                      ?.toInt() ??
                  0;
          txn.update(ref, {'quantity': currentQty - item.quantity});
        }

        return orderRef.id;
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('فشل تنفيذ الطلب: ${e.message}', code: e.code);
    }
  }

  // ---------------------------------------------------------------------
  // STREAMS
  // ---------------------------------------------------------------------

  /// All orders, newest first — Admin view.
  Stream<List<OrderModel>> watchAllOrders() {
    return _ordersCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());
  }

  /// Orders belonging to one customer — Customer "My Orders" view.
  Stream<List<OrderModel>> watchCustomerOrders(String customerId) {
    return _ordersCol
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());
  }

  /// Active (pending/preparing) orders — Worker production queue.
  Stream<List<OrderModel>> watchWorkerQueue() {
    return _ordersCol
        .where('status', whereIn: OrderStatus.activeForWorker)
        .orderBy('createdAt', descending: false) // FIFO queue
        .snapshots()
        .map((s) => s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());
  }

  // ---------------------------------------------------------------------
  // MUTATIONS
  // ---------------------------------------------------------------------

  Future<void> updateStatus(String orderId, String newStatus) async {
    final data = <String, dynamic>{'status': newStatus};
    if (newStatus == OrderStatus.completed) {
      data['completedAt'] = Timestamp.now();
    }
    await _ordersCol.doc(orderId).update(data);
  }

  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    await _ordersCol.doc(orderId).update({'paymentStatus': paymentStatus});
  }

  /// Worker marks order finished. Equivalent to [updateStatus] with
  /// [OrderStatus.completed] but named explicitly for the Worker flow.
  Future<void> markFinishedByWorker(String orderId) =>
      updateStatus(orderId, OrderStatus.completed);

  /// Worker note — visible ONLY to Admin (enforced via Firestore rules,
  /// the field is simply never read/rendered in the Worker/Customer UI).
  Future<void> setWorkerNote(String orderId, String note) async {
    await _ordersCol.doc(orderId).update({'workerNote': note});
  }

  Future<void> deleteOrder(String orderId) async {
    await _ordersCol.doc(orderId).delete();
  }
}
