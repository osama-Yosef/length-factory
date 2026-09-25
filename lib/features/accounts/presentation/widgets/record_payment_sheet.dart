import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/submission_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/account_actions_cubit.dart';

/// Admin records a payment from a customer. Requires [AccountActionsCubit].
class RecordPaymentSheet extends StatefulWidget {
  final UserEntity customer;
  const RecordPaymentSheet({super.key, required this.customer});

  static Future<void> show(BuildContext context, UserEntity customer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AccountActionsCubit>(),
        child: RecordPaymentSheet(customer: customer),
      ),
    );
  }

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitted = false;

  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final admin = context.read<AuthCubit>().state.user;
    if (admin == null) return;
    _submitted = true;
    context.read<AccountActionsCubit>().recordPayment(
          customer: widget.customer,
          admin: admin,
          amount: _amount,
          notes: _notesCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.customer.balance;
    final remaining = balance - _amount;

    return BlocConsumer<AccountActionsCubit, SubmissionState>(
      listener: (context, state) {
        if (_submitted && state is SubmissionSuccess) Navigator.of(context).pop();
      },
      builder: (context, state) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('تسجيل دفعة — ${widget.customer.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Text('الرصيد المستحق',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const Spacer(),
                      Text(FormatUtils.currency(balance),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, color: AppColors.error, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'قيمة الدفعة (ج.م) *',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    suffixIcon: TextButton(
                      onPressed: () => setState(() => _amountCtrl.text =
                          balance == balance.roundToDouble() ? balance.toInt().toString() : balance.toString()),
                      child: const Text('المبلغ كاملًا'),
                    ),
                  ),
                  validator: (v) {
                    final e = Validators.positiveNumber(v, field: 'قيمة الدفعة');
                    if (e != null) return e;
                    if (_amount - balance > 0.001) return 'القيمة أكبر من الرصيد المستحق';
                    return null;
                  },
                ),
                if (_amount > 0 && _amount <= balance)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'المتبقي بعد الدفعة: ${FormatUtils.currency(remaining)}',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800),
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    hintText: 'مثال: نقدًا / تحويل بنكي',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'تأكيد الدفعة',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  isLoading: state is SubmissionLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
