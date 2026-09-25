import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../cubit/users_cubit.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/user_avatar.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العملاء')),
      body: BlocBuilder<UsersCubit, UsersState>(
        builder: (context, state) {
          final cubit = context.read<UsersCubit>();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: AppSearchField(hint: 'بحث بالاسم أو الهاتف أو البريد...', onChanged: cubit.search),
              ),
              if (state.status == LoadStatus.loaded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'إجمالي المستحقات: ${FormatUtils.currency(state.totalBalance)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.error),
                        ),
                      ),
                      FilterChip(
                        label: const Text('عليهم مستحقات'),
                        selected: state.onlyWithBalance,
                        onSelected: cubit.toggleOnlyWithBalance,
                      ),
                    ],
                  ),
                ),
              Expanded(child: _body(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, UsersState state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: state.error ?? 'تعذر تحميل العملاء',
          onRetry: context.read<UsersCubit>().retry,
        );
      case LoadStatus.loaded:
        final list = state.visible;
        if (list.isEmpty) {
          return const EmptyView(icon: Icons.people_outline, title: 'لا يوجد عملاء');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _CustomerCard(customer: list[i]),
        );
    }
  }
}

class _CustomerCard extends StatelessWidget {
  final UserEntity customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final owes = customer.balance > 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => CustomerDetailsScreen.open(context, customer.uid),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  UserAvatar(initial: customer.initial),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(customer.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                            ),
                            if (!customer.isActive) ...[
                              const SizedBox(width: 6),
                              const AppBadge(
                                label: 'موقوف',
                                foreground: AppColors.error,
                                background: AppColors.errorSoft,
                              ),
                            ],
                          ],
                        ),
                        Text(customer.phone,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('الرصيد المستحق',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        FormatUtils.currency(customer.balance),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: owes ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (owes) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => RecordPaymentSheet.show(context, customer),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('تسجيل دفعة'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
