import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/customer_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('العملاء')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: provider.setSearch,
              decoration: const InputDecoration(
                hintText: 'بحث باسم العميل أو رقم الهاتف...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.filteredCustomers.isEmpty
                    ? const Center(
                        child: Text('لا يوجد عملاء بعد',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: provider.filteredCustomers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final customer = provider.filteredCustomers[i];
                          return _CustomerCard(
                            customer: customer,
                            onPayment: () =>
                                _showPaymentDialog(context, customer),
                            onHistory: () =>
                                _showPaymentHistory(context, customer),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, UserModel customer) {
    final provider = context.read<CustomerProvider>();
    final authProvider = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: _PaymentSheet(customer: customer),
      ),
    );
  }

  void _showPaymentHistory(BuildContext context, UserModel customer) {
    final provider = context.read<CustomerProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _PaymentHistorySheet(customer: customer),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final UserModel customer;
  final VoidCallback onPayment;
  final VoidCallback onHistory;

  const _CustomerCard({
    required this.customer,
    required this.onPayment,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0] : '?',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(customer.phone,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('الرصيد المستحق',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      FormatUtils.currency(customer.balance),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: customer.balance > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onHistory,
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('السجل', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: customer.balance > 0 ? onPayment : null,
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('تسجيل دفعة',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white),
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

// ── Payment Sheet ──────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final UserModel customer;
  const _PaymentSheet({required this.customer});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = context.read<AuthProvider>().currentUser!;
    final success = await context.read<CustomerProvider>().recordPayment(
          customerId: widget.customer.uid,
          amount: double.parse(_amountCtrl.text.trim()),
          adminId: admin.uid,
          adminName: admin.name,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدفعة بنجاح ✓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تسجيل دفعة — ${widget.customer.name}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'الرصيد الحالي: ${FormatUtils.currency(widget.customer.balance)}',
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'قيمة الدفعة (ج.م) *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'أدخل قيمة الدفعة';
                  final amount = double.tryParse(v.trim());
                  if (amount == null || amount <= 0) return 'قيمة غير صحيحة';
                  if (amount > widget.customer.balance) {
                    return 'القيمة أكبر من الرصيد المستحق';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              ),
              const SizedBox(height: 20),
              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(provider.errorMessage!,
                      style: const TextStyle(color: AppColors.error)),
                ),
              PrimaryButton(
                label: 'تأكيد الدفعة',
                onPressed: _submit,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment History Sheet ──────────────────────────────────────────────────────

class _PaymentHistorySheet extends StatelessWidget {
  final UserModel customer;
  const _PaymentHistorySheet({required this.customer});

  @override
  Widget build(BuildContext context) {
    final stream =
        context.read<CustomerProvider>().watchPayments(customer.uid);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سجل المدفوعات — ${customer.name}',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final payments = snapshot.data ?? [];
                  if (payments.isEmpty) {
                    return const Center(
                        child: Text('لا توجد مدفوعات بعد',
                            style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.separated(
                    controller: ctrl,
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = payments[i];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.success,
                          child: Icon(Icons.arrow_downward,
                              color: Colors.white, size: 18),
                        ),
                        title: Text(FormatUtils.currency(p.amount),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(FormatUtils.dateTime(p.date),
                                style: const TextStyle(fontSize: 11)),
                            if (p.notes != null && p.notes!.isNotEmpty)
                              Text(p.notes!,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        trailing: Text('بواسطة:\n${p.adminName}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
