import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Global authentication state shared across the whole app via
/// `ChangeNotifierProvider` at the root (see main.dart).
///
/// This is the single source of truth for "who is logged in" and
/// "what is their role" — [GoRouter]'s redirect logic listens to this
/// provider to decide which shell (Admin/Customer/Worker) to show.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _init();
  }

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  String? errorMessage;
  bool isLoading = false;

  bool get isAdmin => currentUser?.isAdmin ?? false;
  bool get isCustomer => currentUser?.isCustomer ?? false;
  bool get isWorker => currentUser?.isWorker ?? false;

  void _init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        currentUser = null;
        status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      try {
        final profile = await _authService.fetchCurrentUserProfile();
        currentUser = profile;
        status = profile != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
      } catch (_) {
        currentUser = null;
        status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _authService.signIn(email: email, password: password);
      status = AuthStatus.authenticated;
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _authService.registerCustomer(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
      status = AuthStatus.authenticated;
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordReset(email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
