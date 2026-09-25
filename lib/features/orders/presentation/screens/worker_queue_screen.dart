import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/cubit/submission_state.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/logout_button.dart';
import '../../data/services/invoice_pdf_service.dart';
import '../../domain/entities/order_entity.dart';
import '../cubit/order_actions_cubit.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_items_list.dart';

/// Worker production queue (FIFO). Workers never see prices or balances.
class WorkerQueueScreen extends StatelessWidget {
  const WorkerQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthCubit, String>((c) => c.state.user?.name ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الإنتاج'),
        actions: const [LogoutButton()],
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          final cubit = context.read<OrdersCubit>();
          return Column(
            children: [
              _WorkerBanner(
                name: name,
                pending: state.countOf(OrderStatus.pending),
                preparing: state.countOf(OrderStatus.preparing),
              ),
              _FilterRow(selected: state.statusFilter, onSelected: cubit.setStatusFilter),
              Expanded(child: _body(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, OrdersState state) {
    if (state.status == LoadStatus.loading) return const LoadingView();
    if (state.status == LoadStatus.error) {
      return ErrorView(
        message: state.error ?? 'تعذر تحميل الطلبات',
        onRetry: context.read<OrdersCubit>().retry,
      );
    }
    final orders = state.visible;
    if (orders.isEmpty) {
      return const EmptyView(
        icon: Icons.task_alt_rounded,
        title: 'لا توجد طلبات في الانتظار',
        subtitle: 'كل الطلبات تم تنفيذها 🎉',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _WorkerOrderCard(order: orders[i], queueNumber: i + 1),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _FilterRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const options = <String?>[null, OrderStatus.pending, OrderStatus.preparing];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          for (final s in options) ...[
            ChoiceChip(
              label: Text(s == null ? 'الكل' : FormatUtils.orderStatus(s)),
              selected: selected == s,
              onSelected: (_) => onSelected(s),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _WorkerBanner extends StatelessWidget {
  final String name;
  final int pending;
  final int preparing;

  const _WorkerBanner({required this.name, required this.pending, required this.preparing});

  @override
  Widget build(BuildContext context) {
    Widget counter(String label, int value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.engineering_rounded, color: AppColors.primary, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مرحبًا $name 👷',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              counter('منتظر', pending, AppColors.statusPending),
              const SizedBox(width: 10),
              counter('جارٍ التنفيذ', preparing, AppColors.statusPreparing),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkerOrderCard extends StatelessWidget {
  final OrderEntity order;
  final int queueNumber;

  const _WorkerOrderCard({required this.order, required this.queueNumber});

  Future<void> _advance(BuildContext context) async {
    final cubit = context.read<OrderActionsCubit>();
    final next = order.isPending ? OrderStatus.preparing : OrderStatus.completed;
    final ok = await UiHelpers.confirm(
      context,
      title: order.isPending ? 'بدء التنفيذ؟' : 'تأكيد الإنجاز؟',
      message: order.isPending
          ? 'سيتم تغيير حالة الطلب #${order.orderNumber} إلى "جارٍ التنفيذ".'
          : 'هل أنهيت تنفيذ الطلب #${order.orderNumber}؟ سيختفي من قائمة الإنتاج.',
      confirmLabel: order.isPending ? 'بدء' : 'تم الإنجاز',
      icon: order.isPending ? Icons.play_circle_outline : Icons.task_alt,
    );
    if (ok) cubit.changeStatus(order, next);
  }

  Future<void> _editNote(BuildContext context) async {
    final cubit = context.read<OrderActionsCubit>();
    final ctrl = TextEditingController(text: order.workerNote ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ملاحظة للإدارة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هذه الملاحظة تظهر للإدارة فقط.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'مثال: يحتاج قص إضافي، خامة ناقصة...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('حفظ')),
        ],
      ),
    );
    ctrl.dispose();
    if (note != null) cubit.saveWorkerNote(order, note);
  }

  Future<void> _printWorkOrder(BuildContext context) async {
    try {
      await sl<InvoicePdfService>().printInvoice(order, showPrices: false);
    } catch (_) {
      if (context.mounted) {
        UiHelpers.showSnack(context, 'تعذر إنشاء أمر التشغيل', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<OrderActionsCubit, bool>((c) => c.state is SubmissionLoading);
    final isPending = order.isPending;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.secondarySoft, shape: BoxShape.circle),
                  child: Text(
                    '$queueNumber',
                    style: const TextStyle(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('طلب #${order.orderNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(
                        '${order.customerName} • ${FormatUtils.dateTime(order.createdAt)}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),
            const Divider(height: 24),
            OrderItemsList(items: order.items, showPrices: false),
            if (order.hasCustomerNote) ...[
              const SizedBox(height: 8),
              _Note(
                icon: Icons.chat_bubble_outline,
                text: 'ملاحظة العميل: ${order.customerNote}',
                color: AppColors.info,
                bg: AppColors.infoSoft,
              ),
            ],
            if (order.hasWorkerNote) ...[
              const SizedBox(height: 8),
              _Note(
                icon: Icons.sticky_note_2_outlined,
                text: 'ملاحظتك: ${order.workerNote}',
                color: AppColors.warning,
                bg: AppColors.warningSoft,
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton.outlined(
                  tooltip: 'طباعة أمر التشغيل',
                  onPressed: () => _printWorkOrder(context),
                  icon: const Icon(Icons.print_outlined),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : () => _editNote(context),
                    icon: const Icon(Icons.edit_note, size: 20),
                    label: Text(order.hasWorkerNote ? 'تعديل الملاحظة' : 'إضافة ملاحظة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPending ? AppColors.primary : AppColors.success,
                    ),
                    onPressed: loading ? null : () => _advance(context),
                    icon: Icon(isPending ? Icons.play_arrow_rounded : Icons.check_circle_rounded),
                    label: Text(isPending ? 'بدء التنفيذ' : 'تم الإنجاز'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;

  const _Note({required this.icon, required this.text, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
