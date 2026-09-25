import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/product_entity.dart';

/// Shows stock state: out of stock / low / available (with quantity).
class StockBadge extends StatelessWidget {
  final ProductEntity product;
  final bool showQuantity;

  const StockBadge({super.key, required this.product, this.showQuantity = true});

  @override
  Widget build(BuildContext context) {
    if (product.isOutOfStock) {
      return const AppBadge(
        label: 'نفدت الكمية',
        foreground: AppColors.error,
        background: AppColors.errorSoft,
        icon: Icons.remove_shopping_cart_outlined,
      );
    }
    if (product.isLowStock) {
      return AppBadge(
        label: showQuantity ? 'كمية محدودة: ${product.quantity}' : 'كمية محدودة',
        foreground: AppColors.warning,
        background: AppColors.warningSoft,
        icon: Icons.warning_amber_rounded,
      );
    }
    return AppBadge(
      label: showQuantity ? 'متاح: ${product.quantity}' : 'متاح',
      foreground: AppColors.success,
      background: AppColors.successSoft,
      icon: Icons.check_circle_outline,
    );
  }
}
