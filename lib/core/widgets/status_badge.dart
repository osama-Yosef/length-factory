import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isPayment;

  const StatusBadge({super.key, required this.status, this.isPayment = false});

  @override
  Widget build(BuildContext context) {
    final color = isPayment ? _paymentColor(status) : AppColors.forOrderStatus(status);
    final label = isPayment ? _paymentLabel(status) : _orderLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _orderLabel(String s) => switch (s) {
        OrderStatus.pending => 'قيد الانتظار',
        OrderStatus.preparing => 'جاري التحضير',
        OrderStatus.completed => 'مكتمل',
        OrderStatus.cancelled => 'ملغي',
        _ => s,
      };

  Color _paymentColor(String s) => switch (s) {
        PaymentStatus.paid => AppColors.success,
        PaymentStatus.partiallyPaid => AppColors.warning,
        _ => AppColors.error,
      };

  String _paymentLabel(String s) => switch (s) {
        PaymentStatus.paid => 'مدفوع',
        PaymentStatus.partiallyPaid => 'مدفوع جزئياً',
        _ => 'غير مدفوع',
      };
}
