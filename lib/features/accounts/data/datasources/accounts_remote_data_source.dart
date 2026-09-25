import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/payment_model.dart';

/// Returns a [FirebaseAuth] bound to a *secondary* Firebase app, so that
/// creating a staff account doesn't replace the admin's own session.
typedef SecondaryAuthProvider = Future<FirebaseAuth> Function();

Future<FirebaseAuth> firebaseSecondaryAuth() async {
  const name = 'staff-creator';
  FirebaseApp app;
  try {
    app = Firebase.app(name);
  } on FirebaseException {
    app = await Firebase.initializeApp(name: name, options: Firebase.app().options);
  }
  return FirebaseAuth.instanceFor(app: app);
}

abstract class AccountsRemoteDataSource {
  Stream<List<UserModel>> watchCustomers();
  Stream<List<UserModel>> watchStaff();
  Stream<List<PaymentModel>> watchPayments(String customerId);
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    required String adminId,
    required String adminName,
    String? notes,
  });
  Future<void> setUserActive(String uid, bool isActive);
  Future<void> createStaffAccount({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  });
  Future<void> updateProfile({required String uid, required String name, required String phone});
}

class AccountsRemoteDataSourceImpl implements AccountsRemoteDataSource {
  final FirebaseFirestore _firestore;
  final SecondaryAuthProvider _secondaryAuth;

  AccountsRemoteDataSourceImpl(this._firestore, this._secondaryAuth);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);
  CollectionReference<Map<String, dynamic>> get _payments =>
      _firestore.collection(FirestoreCollections.payments);

  List<UserModel> _mapUsers(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();

  @override
  Stream<List<UserModel>> watchCustomers() => _users
      .where('role', isEqualTo: UserRole.customer)
      .orderBy('name')
      .snapshots()
      .map(_mapUsers);

  @override
  Stream<List<UserModel>> watchStaff() => _users
      .where('role', whereIn: UserRole.staff)
      .snapshots()
      .map((s) => _mapUsers(s)..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Stream<List<PaymentModel>> watchPayments(String customerId) => _payments
      .where('customerId', isEqualTo: customerId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList());

  /// Example: balance 5000, pays 2000 → remaining 3000.
  @override
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    required String adminId,
    required String adminName,
    String? notes,
  }) {
    return _firestore.runTransaction((txn) async {
      final customerRef = _users.doc(customerId);
      final snap = await txn.get(customerRef);
      if (!snap.exists) throw const FirestoreException('العميل غير موجود');

      final balance = (snap.data()?['balance'] as num?)?.toDouble() ?? 0;
      // Small epsilon avoids floating point false negatives.
      if (amount - balance > 0.001) {
        throw FirestoreException(
          'قيمة الدفعة (${FormatUtils.currency(amount)}) أكبر من الرصيد الحالي (${FormatUtils.currency(balance)})',
        );
      }

      txn.update(customerRef, {'balance': balance - amount});
      final paymentRef = _payments.doc();
      txn.set(
        paymentRef,
        PaymentModel(
          id: paymentRef.id,
          customerId: customerId,
          amount: amount,
          date: DateTime.now(),
          adminId: adminId,
          adminName: adminName,
          notes: notes,
        ).toMap(),
      );
    });
  }

  @override
  Future<void> setUserActive(String uid, bool isActive) =>
      _users.doc(uid).update({'isActive': isActive});

  @override
  Future<void> createStaffAccount({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    final auth = await _secondaryAuth();
    UserCredential cred;
    try {
      cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
    final uid = cred.user!.uid;
    try {
      await _users.doc(uid).set(UserModel(
            uid: uid,
            name: name,
            phone: phone,
            email: email,
            role: role,
            createdAt: DateTime.now(),
          ).toMap());
    } catch (_) {
      await cred.user?.delete();
      rethrow;
    } finally {
      await auth.signOut();
    }
  }

  @override
  Future<void> updateProfile({required String uid, required String name, required String phone}) =>
      _users.doc(uid).update({'name': name, 'phone': phone});
}
