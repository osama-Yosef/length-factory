import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';
import '../../data/models/user_model.dart';

/// Wraps [FirebaseAuth] and exposes a simplified, exception-safe API.
///
/// Every method converts raw [FirebaseAuthException]s into our own
/// [AuthException] so the Presentation layer never has to import
/// `firebase_auth` directly (Dependency Inversion).
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Logs in and returns the full [UserModel] (including role) from Firestore.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      return await _fetchUserDocOrThrow(uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  /// Registers a new Customer account (the only self-serve role).
  /// Admin/Worker accounts are created by an Admin from the dashboard.
  Future<UserModel> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      final userModel = UserModel(
        uid: uid,
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        role: UserRole.customer,
        balance: 0,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Fetches the current logged-in user's role/profile document.
  /// Returns null if not authenticated.
  Future<UserModel?> fetchCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _fetchUserDocOrThrow(uid);
  }

  Future<UserModel> _fetchUserDocOrThrow(String uid) async {
    final doc =
        await _firestore.collection(FirestoreCollections.users).doc(uid).get();

    if (!doc.exists) {
      // Edge case: Auth account exists but Firestore profile is missing
      // (e.g. created manually in Firebase console). Sign out to avoid
      // an inconsistent app state.
      await _auth.signOut();
      throw const AuthException('بيانات الحساب غير مكتملة، تواصل مع الإدارة');
    }

    return UserModel.fromMap(doc.data()!, doc.id);
  }
}
