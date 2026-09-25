import 'package:flutter/material.dart';

/// Light, high-contrast palette.
///
/// Backgrounds are light, but every foreground (text, icons, borders,
/// status labels) is dark enough to stay clearly readable (WCAG AA+).
class AppColors {
  AppColors._();

  // Brand — Blue
  static const Color primary = Color(0xFF1D4ED8); // blue-700
  static const Color primaryDark = Color(0xFF1E3A8A); // blue-900
  static const Color primaryLight = Color(0xFF3B82F6); // blue-500
  static const Color primarySoft = Color(0xFFEFF4FF); // tinted background

  // Accent — Orange (industrial)
  static const Color secondary = Color(0xFFEA580C); // orange-600
  static const Color secondaryDark = Color(0xFFC2410C); // orange-700
  static const Color secondarySoft = Color(0xFFFFF1E6);

  // Surfaces
  static const Color background = Color(0xFFF6F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  // Borders
  static const Color border = Color(0xFFD5DCE6);
  static const Color borderStrong = Color(0xFFB6C2D2);

  // Text
  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textMuted = Color(0xFF64748B); // slate-500

  // Semantic (dark enough for text on white)
  static const Color success = Color(0xFF15803D);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFB45309);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0369A1);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // Order status
  static const Color statusPending = warning;
  static const Color statusPreparing = primary;
  static const Color statusCompleted = success;
  static const Color statusCancelled = error;

  /// Foreground color for an order status.
  static Color forOrderStatus(String status) {
    switch (status) {
      case 'preparing':
        return statusPreparing;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
        return statusCancelled;
      case 'pending':
      default:
        return statusPending;
    }
  }

  /// Soft background color for an order status badge.
  static Color softForOrderStatus(String status) {
    switch (status) {
      case 'preparing':
        return primarySoft;
      case 'completed':
        return successSoft;
      case 'cancelled':
        return errorSoft;
      case 'pending':
      default:
        return warningSoft;
    }
  }

  static Color forPaymentStatus(String status) {
    switch (status) {
      case 'paid':
        return success;
      case 'partially_paid':
        return warning;
      default:
        return error;
    }
  }

  static Color softForPaymentStatus(String status) {
    switch (status) {
      case 'paid':
        return successSoft;
      case 'partially_paid':
        return warningSoft;
      default:
        return errorSoft;
    }
  }
}
