import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/payments_cubit.dart';

/// Payment history (non-scrolling; embed inside a ListView).
class PaymentsList extends StatelessWidget {
  const PaymentsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentsCubit, PaymentsState>(
      builder: (context, state) {
        if (state.status == LoadStatus.loading) {
          return const Padding(padding: EdgeInsets.all(24), child: LoadingView());
        }
        if (state.status == LoadStatus.error) {
          return ErrorView(
            message: state.error ?? 'تعذر تحميل المدفوعات',
            onRetry: context.read<PaymentsCubit>().retry,
          );
        }
        if (state.payments.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.payments_outlined, size: 40, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('لا توجد مدفوعات بعد',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }
        return Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('إجمالي المدفوع', style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: Text(
                  FormatUtils.currency(state.totalPaid),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(height: 1),
              for (var i = 0; i < state.payments.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                _PaymentTile(
                  amount: state.payments[i].amount,
                  date: state.payments[i].date,
                  adminName: state.payments[i].adminName,
                  notes: state.payments[i].notes,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final double amount;
  final DateTime date;
  final String adminName;
  final String? notes;

  const _PaymentTile({required this.amount, required this.date, required this.adminName, this.notes});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.successSoft,
        child: Icon(Icons.south_west_rounded, color: AppColors.success, size: 20),
      ),
      title: Text(
        FormatUtils.currency(amount),
        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.success),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(FormatUtils.dateTime(date),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          if (notes != null && notes!.isNotEmpty)
            Text(notes!, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
        ],
      ),
      trailing: Text(
        'بواسطة\n$adminName',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
      ),
    );
  }
}
