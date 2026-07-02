import 'package:flutter/material.dart';

/// Brand color palette: "Dark Blue & Orange" industrial factory theme.
///
/// Centralizing raw color values here (instead of scattering
/// `Color(0xFF...)` across widgets) makes re-theming trivial and keeps
/// [AppTheme] readable.
class AppColors {
  AppColors._();

  // Primary - Dark Blue
  static const Color primaryDark = Color(0xFF0B1F3A);
  static const Color primary = Color(0xFF13315C);
  static const Color primaryLight = Color(0xFF1F4E8C);

  // Secondary - Orange (industrial / spark accent)
  static const Color secondary = Color(0xFFF77F00);
  static const Color secondaryLight = Color(0xFFFFA94D);
  static const Color secondaryDark = Color(0xFFD66600);

  // Neutrals - Light theme
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Neutrals - Dark theme
  static const Color darkBackground = Color(0xFF0A0E17);
  static const Color darkSurface = Color(0xFF131A28);
  static const Color darkCard = Color(0xFF1A2235);

  // Status colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF1C40F);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Order status colors
  static const Color statusPending = Color(0xFFF1C40F);
  static const Color statusPreparing = Color(0xFF3498DB);
  static const Color statusCompleted = Color(0xFF2ECC71);
  static const Color statusCancelled = Color(0xFFE74C3C);

  // Text
  static const Color textPrimaryLight = Color(0xFF1A1F2B);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF2F4F8);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  /// Returns the color associated with a given order status string.
  static Color forOrderStatus(String status) {
    switch (status) {
      case 'pending':
        return statusPending;
      case 'preparing':
        return statusPreparing;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
        return statusCancelled;
      default:
        return statusPending;
    }
  }
}
