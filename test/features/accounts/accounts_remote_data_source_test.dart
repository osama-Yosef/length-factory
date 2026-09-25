import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:length_factory/core/errors/exceptions.dart';
import 'package:length_factory/features/accounts/data/datasources/accounts_remote_data_source.dart';

void main() {
  late FakeFirebaseFirestore db;
  late AccountsRemoteDataSourceImpl ds;

  setUp(() async {
    db = FakeFirebaseFirestore();
    ds = AccountsRemoteDataSourceImpl(db, () async => MockFirebaseAuth());
    await db.collection('users').doc('c1').set({
      'name': 'عميل',
      'role': 'customer',
      'balance': 5000,
      'createdAt': Timestamp.now(),
    });
    await db.collection('users').doc('w1').set({
      'name': 'عامل',
      'role': 'worker',
      'createdAt': Timestamp.now(),
    });
  });

  test('recordPayment: 5000 - 2000 = 3000 and a payment record is saved', () async {
    await ds.recordPayment(customerId: 'c1', amount: 2000, adminId: 'a1', adminName: 'المدير');

    final user = await db.collection('users').doc('c1').get();
    expect(user.data()!['balance'], 3000);
    final payments = await ds.watchPayments('c1').first;
    expect(payments.single.amount, 2000);
    expect(payments.single.adminName, 'المدير');
  });

  test('recordPayment rejects over-payment', () async {
    await expectLater(
      ds.recordPayment(customerId: 'c1', amount: 6000, adminId: 'a1', adminName: 'x'),
      throwsA(isA<FirestoreException>()),
    );
  });

  test('watchCustomers / watchStaff split users by role', () async {
    final customers = await ds.watchCustomers().first;
    final staff = await ds.watchStaff().first;
    expect(customers.map((u) => u.uid), ['c1']);
    expect(staff.map((u) => u.uid), ['w1']);
  });

  test('createStaffAccount writes the profile with the chosen role', () async {
    await ds.createStaffAccount(
      name: 'عامل جديد',
      phone: '01000000000',
      email: 'w2@test.com',
      password: '123456',
      role: 'worker',
    );
    final staff = await ds.watchStaff().first;
    expect(staff.any((u) => u.name == 'عامل جديد' && u.isWorker), isTrue);
  });

  test('setUserActive toggles isActive', () async {
    await ds.setUserActive('c1', false);
    final doc = await db.collection('users').doc('c1').get();
    expect(doc.data()!['isActive'], isFalse);
  });
}
