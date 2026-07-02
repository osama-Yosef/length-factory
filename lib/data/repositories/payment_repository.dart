import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';

/// Manages Customer accounts: balance, payment history, and the
/// Admin-only "confirm payment" flow.
class CustomerRepository {
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  CustomerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _paymentsCol =>
      _firestore.collection(FirestoreCollections.payments);

  /// Live list of all customers, used by Admin "Customers" tab.
  Stream<List<UserModel>> watchCustomers() {
    return _usersCol
        .where('role', isEqualTo: UserRole.customer)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<UserModel?> watchCustomer(String uid) {
    return _usersCol.doc(uid).snapshots().map(
          (d) => d.exists ? UserModel.fromMap(d.data()!, d.id) : null,
        );
  }

  Stream<List<PaymentModel>> watchPaymentHistory(String customerId) {
    return _paymentsCol
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList());
  }

  /// Admin confirms a payment.
  ///
  /// Example from the spec:
  ///   Current Balance = 5000, Customer Pays = 2000 -> Remaining = 3000.
  ///
  /// Implemented as a transaction so the payment record and the balance
  /// decrement are always consistent.
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    required String adminId,
    required String adminName,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw const FirestoreException('قيمة الدفعة يجب أن تكون أكبر من صفر');
    }

    try {
      await _firestore.runTransaction((txn) async {
        final customerRef = _usersCol.doc(customerId);
        final snap = await txn.get(customerRef);

        if (!snap.exists) {
          throw const FirestoreException('العميل غير موجود');
        }

        final currentBalance = (snap.data()?['balance'] as num?)?.toDouble() ?? 0;
        final newBalance = currentBalance - amount;

        // Business rule: balance should not go negative due to an
        // over-payment. Admin should be warned in the UI before this
        // point, but we guard here as the last line of defense.
        if (newBalance < 0) {
          throw FirestoreException(
            'قيمة الدفعة ($amount) أكبر من الرصيد الحالي ($currentBalance)',
          );
        }

        txn.update(customerRef, {'balance': newBalance});

        final paymentRef = _paymentsCol.doc(_uuid.v4());
        final payment = PaymentModel(
          id: paymentRef.id,
          customerId: customerId,
          amount: amount,
          date: DateTime.now(),
          adminId: adminId,
          adminName: adminName,
          notes: notes,
        );
        txn.set(paymentRef, payment.toMap());
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('فشل تسجيل الدفعة: ${e.message}', code: e.code);
    }
  }

  /// Admin creates a Worker or Admin account directly (not self-serve).
  Future<void> createStaffAccount({
    required String uid,
    required String name,
    required String phone,
    required String email,
    required String role, // UserRole.admin or UserRole.worker
  }) async {
    final user = UserModel(
      uid: uid,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      role: role,
      createdAt: DateTime.now(),
    );
    await _usersCol.doc(uid).set(user.toMap());
  }

  Future<void> setActive(String uid, bool isActive) async {
    await _usersCol.doc(uid).update({'isActive': isActive});
  }
}
