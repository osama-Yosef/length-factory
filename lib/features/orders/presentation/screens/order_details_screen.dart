import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/cubit/submission_state.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/services/invoice_pdf_service.dart';
import '../../domain/entities/order_entity.dart';
import '../cubit/order_actions_cubit.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_items_list.dart';

/// Live order details.
///
/// Requires an [OrdersCubit] above it; when [isAdmin] also an
/// [OrderActionsCubit] (status / payment / delete actions).
class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final bool isAdmin;

  const OrderDetailsScreen({super.key, required this.orderId, this.isAdmin = false});

  /// Opens the screen re-providing the caller's Cubits.
  static Future<void> open(BuildContext context, String orderId, {bool isAdmin = false}) {
    return UiHelpers.push(
      context,
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<OrdersCubit>()),
          if (isAdmin) BlocProvider.value(value: context.read<OrderActionsCubit>()),
        ],
        child: OrderDetailsScreen(orderId: orderId, isAdmin: isAdmin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = context.select<OrdersCubit, OrderEntity?>((c) => c.state.byId(orderId));

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطلب')),
        body: const EmptyView(
          icon: Icons.receipt_long_outlined,
          title: 'الطلب غير موجود',
          subtitle: 'ربما تم حذفه',
        ),
      );
    }

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeaderCard(order: order),
        const SizedBox(height: 12),
        if (isAdmin) ...[
          _CustomerCard(order: order),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('المنتجات (${order.totalItemsCount} قطعة)',
                    icon: Icons.inventory_2_outlined),
                OrderItemsList(items: order.items),
                const Divider(height: 24),
                InfoRow(
                  label: 'إجمالي الطلب',
                  value: FormatUtils.currency(order.totalPrice),
                  valueColor: AppColors.primary,
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        if (order.hasCustomerNote) ...[
          const SizedBox(height: 12),
          _NoteBox(
            title: 'ملاحظة العميل',
            text: order.customerNote!,
            color: AppColors.info,
            background: AppColors.infoSoft,
            icon: Icons.chat_bubble_outline,
          ),
        ],
        if (isAdmin && order.hasWorkerNote) ...[
          const SizedBox(height: 12),
          _NoteBox(
            title: 'ملاحظة العامل',
            text: order.workerNote!,
            color: AppColors.warning,
            background: AppColors.warningSoft,
            icon: Icons.engineering_outlined,
          ),
        ],
        if (isAdmin) ...[
          const SizedBox(height: 12),
          _AdminActions(order: order),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _runInvoice(context, () => sl<InvoicePdfService>().printInvoice(order)),
                icon: const Icon(Icons.print_outlined),
                label: const Text('طباعة الفاتورة'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _runInvoice(context, () => sl<InvoicePdfService>().shareInvoice(order)),
                icon: const Icon(Icons.share_outlined),
                label: const Text('مشاركة PDF'),
              ),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text('طلب #${order.orderNumber}')),
      body: body,
    );
  }

  Future<void> _runInvoice(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        UiHelpers.showSnack(context, 'تعذر إنشاء الفاتورة، تحقق من اتصالك بالإنترنت', isError: true);
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final OrderEntity order;
  const _HeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'طلب #${order.orderNumber}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'تاريخ الطلب',
              value: FormatUtils.dateTime(order.createdAt),
            ),
            if (order.completedAt != null)
              InfoRow(
                icon: Icons.task_alt,
                label: 'تاريخ الإنجاز',
                value: FormatUtils.dateTime(order.completedAt!),
                valueColor: AppColors.success,
              ),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'حالة الدفع',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                StatusBadge(status: order.paymentStatus, isPayment: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final OrderEntity order;
  const _CustomerCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SectionTitle('بيانات العميل', icon: Icons.person_outline),
            InfoRow(label: 'الاسم', value: order.customerName),
            InfoRow(label: 'الهاتف', value: order.customerPhone),
          ],
        ),
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String title;
  final String text;
  final Color color;
  final Color background;
  final IconData icon;

  const _NoteBox({
    required this.title,
    required this.text,
    required this.color,
    required this.background,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: AppColors.textPrimary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  final OrderEntity order;
  const _AdminActions({required this.order});

  static const _statusIcons = {
    OrderStatus.preparing: Icons.engineering_rounded,
    OrderStatus.completed: Icons.check_circle_rounded,
    OrderStatus.pending: Icons.undo_rounded,
    OrderStatus.cancelled: Icons.cancel_outlined,
  };

  static String _actionLabel(String status) => switch (status) {
        OrderStatus.preparing => 'بدء التنفيذ',
        OrderStatus.completed => 'تم الإنجاز',
        OrderStatus.pending => 'إرجاع للانتظار',
        OrderStatus.cancelled => 'إلغاء الطلب',
        _ => status,
      };

  Future<void> _changeStatus(BuildContext context, String status) async {
    final cubit = context.read<OrderActionsCubit>();
    if (status == OrderStatus.cancelled) {
      final ok = await UiHelpers.confirm(
        context,
        title: 'إلغاء الطلب',
        message: 'سيتم إلغاء الطلب #${order.orderNumber}، وخصم ${FormatUtils.currency(order.totalPrice)} '
            'من رصيد العميل وإرجاع الكميات للمخزون. هل أنت متأكد؟',
        confirmLabel: 'إلغاء الطلب',
        destructive: true,
        icon: Icons.cancel_outlined,
      );
      if (!ok) return;
    }
    cubit.changeStatus(order, status);
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<OrderActionsCubit>();
    final navigator = Navigator.of(context);
    final ok = await UiHelpers.confirm(
      context,
      title: 'حذف الطلب',
      message: order.isCancelled
          ? 'سيتم حذف الطلب نهائيًا. هل أنت متأكد؟'
          : 'سيتم حذف الطلب نهائيًا مع خصم قيمته من رصيد العميل وإرجاع المخزون. هل أنت متأكد؟',
      confirmLabel: 'حذف',
      destructive: true,
      icon: Icons.delete_forever_outlined,
    );
    if (!ok) return;
    await cubit.delete(order);
    if (cubit.state is SubmissionSuccess) navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<OrderActionsCubit>().state is SubmissionLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('إدارة الطلب', icon: Icons.tune),
            if (loading) const LinearProgressIndicator(),
            if (order.nextStatuses.isNotEmpty) ...[
              const Text('تغيير الحالة',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in order.nextStatuses)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forOrderStatus(s),
                        side: BorderSide(color: AppColors.forOrderStatus(s)),
                        backgroundColor: AppColors.softForOrderStatus(s),
                      ),
                      onPressed: loading ? null : () => _changeStatus(context, s),
                      icon: Icon(_statusIcons[s], size: 18),
                      label: Text(_actionLabel(s)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (!order.isCancelled) ...[
              const Text('حالة الدفع',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final p in PaymentStatus.all)
                    ButtonSegment(value: p, label: Text(FormatUtils.paymentStatus(p))),
                ],
                selected: {order.paymentStatus},
                onSelectionChanged: loading
                    ? null
                    : (s) => context.read<OrderActionsCubit>().changePaymentStatus(order, s.first),
              ),
              const SizedBox(height: 16),
            ],
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: loading ? null : () => _delete(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('حذف الطلب نهائيًا'),
            ),
          ],
        ),
      ),
    );
  }
}
