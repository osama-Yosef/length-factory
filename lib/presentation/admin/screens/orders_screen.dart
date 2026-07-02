import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/order_model.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _searchCtrl = TextEditingController();

  static const _filters = [
    ('all', 'الكل'),
    ('pending', 'منتظر'),
    ('preparing', 'جارٍ'),
    ('completed', 'مكتمل'),
    ('cancelled', 'ملغي'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الطلبات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: provider.setSearch,
              decoration: const InputDecoration(
                hintText: 'بحث باسم العميل أو رقم الطلب...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _filters.map((f) {
                final isSelected = provider.statusFilter == f.$1;
                return Padding(
                  padding: const EdgeInsets.only(left: 8, top: 6, bottom: 6),
                  child: FilterChip(
                    label: Text(f.$2),
                    selected: isSelected,
                    onSelected: (_) => provider.setFilter(f.$1),
                    selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.secondary,
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.filteredOrders.isEmpty
                    ? const Center(
                        child: Text('لا توجد طلبات',
                            style:
                                TextStyle(fontSize: 16, color: Colors.grey)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: provider.filteredOrders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          return _OrderCard(
                            order: provider.filteredOrders[i],
                            onStatusChange: (newStatus) => provider
                                .updateStatus(
                                    provider.filteredOrders[i].id, newStatus),
                            onDelete: () => _confirmDelete(
                                context, provider.filteredOrders[i].id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل تريد حذف هذا الطلب نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OrderProvider>().deleteOrder(orderId);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final void Function(String) onStatusChange;
  final VoidCallback onDelete;

  const _OrderCard({
    required this.order,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.forOrderStatus(order.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب #${order.orderNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    FormatUtils.orderStatus(order.status),
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(order.customerName),
                const SizedBox(width: 12),
                const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(order.customerPhone),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'التاريخ: ${FormatUtils.dateTime(order.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // Items
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${item.productName} × ${item.quantity}')),
                      Text(FormatUtils.currency(item.lineTotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                )),

            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي: ${FormatUtils.currency(order.totalPrice)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.secondary),
                ),
                Text(
                  FormatUtils.paymentStatus(order.paymentStatus),
                  style: TextStyle(
                      fontSize: 12,
                      color: order.paymentStatus == 'paid'
                          ? AppColors.success
                          : AppColors.warning),
                ),
              ],
            ),

            if (order.workerNote != null && order.workerNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_outlined,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ملاحظة العامل: ${order.workerNote}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            // Status actions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (order.status == OrderStatus.pending)
                    _ActionBtn(
                      label: 'بدء التنفيذ',
                      icon: Icons.engineering_rounded,
                      color: AppColors.statusPreparing,
                      onTap: () => onStatusChange(OrderStatus.preparing),
                    ),
                  if (order.status == OrderStatus.preparing)
                    _ActionBtn(
                      label: 'تم الإنجاز',
                      icon: Icons.check_circle_outline,
                      color: AppColors.statusCompleted,
                      onTap: () => onStatusChange(OrderStatus.completed),
                    ),
                  if (order.status != OrderStatus.cancelled &&
                      order.status != OrderStatus.completed)
                    _ActionBtn(
                      label: 'إلغاء',
                      icon: Icons.cancel_outlined,
                      color: AppColors.statusCancelled,
                      onTap: () => onStatusChange(OrderStatus.cancelled),
                    ),
                  _ActionBtn(
                    label: 'حذف',
                    icon: Icons.delete_outline,
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
    );
  }
}
