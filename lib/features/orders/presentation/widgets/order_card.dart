import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/order_entity.dart';

/// Compact order summary used in every order list.
class OrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback? onTap;

  /// Hidden for customers viewing their own orders.
  final bool showCustomer;
  final bool showPrice;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.showCustomer = true,
    this.showPrice = true,
  });

  @override
  Widget build(BuildContext context) {
    final itemsPreview = order.items.map((i) => '${i.productName} ×${i.quantity}').join('، ');
    final statusColor = AppColors.forOrderStatus(order.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(start: BorderSide(color: statusColor, width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'طلب #${order.orderNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const Spacer(),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    FormatUtils.dateTime(order.createdAt),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  if (showCustomer) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        order.customerName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                itemsPreview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
              ),
              if (showPrice) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    Text(
                      '${order.totalItemsCount} قطعة',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: order.paymentStatus, isPayment: true),
                    const Spacer(),
                    Text(
                      FormatUtils.currency(order.totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal status filter chips with counts.
class OrderStatusFilterBar extends StatelessWidget {
  final String? selected;
  final int Function(String? status) countOf;
  final ValueChanged<String?> onSelected;
  final List<String?> statuses;

  const OrderStatusFilterBar({
    super.key,
    required this.selected,
    required this.countOf,
    required this.onSelected,
    this.statuses = const [null, 'pending', 'preparing', 'completed', 'cancelled'],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = statuses[i];
          final label = s == null ? 'الكل' : FormatUtils.orderStatus(s);
          return ChoiceChip(
            label: Text('$label (${countOf(s)})'),
            selected: selected == s,
            onSelected: (_) => onSelected(s),
          );
        },
      ),
    );
  }
}
