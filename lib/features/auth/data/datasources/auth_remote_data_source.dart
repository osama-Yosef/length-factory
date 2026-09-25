import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/stream_utils.dart';
import '../../domain/entities/auth_session.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<AuthSession> watchSession();
  Future<void> signIn({required String email, required String password});
  Future<void> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  });
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl(this._auth, this._firestore);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  @override
  Stream<AuthSession> watchSession() {
    return _auth.authStateChanges().switchMap<AuthSession>((user) {
      if (user == null) return Stream.value(const SignedOutSession());
      return _users.doc(user.uid).snapshots().map<AuthSession>((doc) {
        if (!doc.exists || doc.data() == null) return ProfilePendingSession(user.uid);
        return ActiveSession(UserModel.fromMap(doc.data()!, doc.id));
      });
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final doc = await _users.doc(cred.user!.uid).get();
      if (doc.exists && (doc.data()?['isActive'] as bool? ?? true) == false) {
        await _auth.signOut();
        throw const AuthException('تم إيقاف هذا الحساب، تواصل مع الإدارة');
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  @override
  Future<void> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      final user = UserModel(
        uid: uid,
        name: name,
        phone: phone,
        email: email,
        role: UserRole.customer,
        balance: 0,
        createdAt: DateTime.now(),
      );
      try {
        await _users.doc(uid).set(user.toMap());
      } catch (_) {
        // Roll back the orphan auth account so the email can be reused.
        await cred.user?.delete();
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
