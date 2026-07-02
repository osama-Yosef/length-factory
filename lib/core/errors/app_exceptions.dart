/// Base application exception thrown by the Data layer (services/repositories).
///
/// The Presentation layer catches these and shows a localized,
/// user-friendly message — raw Firebase exceptions never leak into the UI.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});

  /// Maps raw FirebaseAuth error codes to friendly Arabic messages.
  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'user-not-found':
        return const AuthException('لا يوجد حساب بهذا البريد الإلكتروني', code: 'user-not-found');
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException('كلمة المرور أو البريد الإلكتروني غير صحيح', code: 'wrong-password');
      case 'email-already-in-use':
        return const AuthException('هذا البريد الإلكتروني مستخدم بالفعل', code: 'email-already-in-use');
      case 'weak-password':
        return const AuthException('كلمة المرور ضعيفة جدًا (6 أحرف على الأقل)', code: 'weak-password');
      case 'invalid-email':
        return const AuthException('صيغة البريد الإلكتروني غير صحيحة', code: 'invalid-email');
      case 'network-request-failed':
        return const AuthException('تحقق من اتصالك بالإنترنت', code: 'network-request-failed');
      case 'too-many-requests':
        return const AuthException('محاولات كثيرة جدًا، حاول لاحقًا', code: 'too-many-requests');
      default:
        return AuthException('حدث خطأ أثناء تسجيل الدخول ($code)', code: code);
    }
  }
}

class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.code});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}
