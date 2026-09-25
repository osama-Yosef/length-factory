import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/entities/order_entity.dart';

/// Line items of an order. Prices are hidden for Workers.
class OrderItemsList extends StatelessWidget {
  final List<OrderItemEntity> items;
  final bool showPrices;

  const OrderItemsList({super.key, required this.items, this.showPrices = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ProductImage(url: item.productImage, width: 48, height: 48, radius: 10, iconSize: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                      if (showPrices)
                        Text(
                          '${FormatUtils.currency(item.unitPrice)} للوحدة',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '× ${item.quantity}',
                    style: const TextStyle(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (showPrices) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 92,
                    child: Text(
                      FormatUtils.currency(item.lineTotal),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
