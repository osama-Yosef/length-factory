import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/format_utils.dart';

/// Colored pill for an order status or a payment status.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isPayment;

  const StatusBadge({super.key, required this.status, this.isPayment = false});

  @override
  Widget build(BuildContext context) {
    final fg = isPayment ? AppColors.forPaymentStatus(status) : AppColors.forOrderStatus(status);
    final bg = isPayment
        ? AppColors.softForPaymentStatus(status)
        : AppColors.softForOrderStatus(status);
    final label = isPayment ? FormatUtils.paymentStatus(status) : FormatUtils.orderStatus(status);

    return AppBadge(label: label, foreground: fg, background: bg);
  }
}

/// Generic pill badge.
class AppBadge extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
