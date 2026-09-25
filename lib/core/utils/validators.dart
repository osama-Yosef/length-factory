import '../constants/app_constants.dart';

/// Reusable form validators (return an Arabic error or null).
class Validators {
  Validators._();

  static String? required(String? v, String message) =>
      (v == null || v.trim().isEmpty) ? message : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
    final ok = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\.\-]+$').hasMatch(v.trim());
    return ok ? null : 'صيغة بريد إلكتروني غير صحيحة';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
    if (v.length < AppConstants.minPasswordLength) {
      return 'كلمة المرور قصيرة جدًا (${AppConstants.minPasswordLength} أحرف على الأقل)';
    }
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'أدخل رقم الهاتف';
    final digits = v.trim();
    if (!RegExp(r'^\d+$').hasMatch(digits)) return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
    if (digits.length != AppConstants.phoneLength) {
      return 'رقم الهاتف يجب أن يكون ${AppConstants.phoneLength} رقمًا';
    }
    return null;
  }

  static String? positiveNumber(String? v, {String field = 'القيمة'}) {
    if (v == null || v.trim().isEmpty) return 'أدخل $field';
    final n = double.tryParse(v.trim());
    if (n == null) return 'رقم غير صحيح';
    if (n <= 0) return '$field يجب أن تكون أكبر من صفر';
    return null;
  }

  static String? nonNegativeInt(String? v, {String field = 'الكمية'}) {
    if (v == null || v.trim().isEmpty) return 'أدخل $field';
    final n = int.tryParse(v.trim());
    if (n == null) return 'أدخل رقمًا صحيحًا';
    if (n < 0) return '$field لا يمكن أن تكون سالبة';
    return null;
  }
}
