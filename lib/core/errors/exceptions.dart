/// Exceptions thrown by the Data layer (data sources / services).
///
/// Repositories catch these and convert them to [Failure]s, so raw
/// Firebase / Dio exceptions never leak into Domain or Presentation.
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
      case 'user-disabled':
        return const AuthException('تم إيقاف هذا الحساب، تواصل مع الإدارة', code: 'user-disabled');
      case 'network-request-failed':
        return const AuthException('تحقق من اتصالك بالإنترنت', code: 'network-request-failed');
      case 'too-many-requests':
        return const AuthException('محاولات كثيرة جدًا، حاول لاحقًا', code: 'too-many-requests');
      default:
        return AuthException('حدث خطأ أثناء المصادقة ($code)', code: code);
    }
  }
}

class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.code});
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode, super.code});
}
