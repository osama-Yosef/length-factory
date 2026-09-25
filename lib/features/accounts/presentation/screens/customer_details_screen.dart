import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../orders/domain/usecases/order_usecases.dart';
import '../../../orders/presentation/cubit/order_actions_cubit.dart';
import '../../../orders/presentation/cubit/orders_cubit.dart';
import '../../../orders/presentation/screens/order_details_screen.dart';
import '../../../orders/presentation/widgets/order_card.dart';
import '../cubit/account_actions_cubit.dart';
import '../cubit/payments_cubit.dart';
import '../cubit/users_cubit.dart';
import '../widgets/payments_list.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/user_avatar.dart';

/// Admin view of one customer: balance, payments, orders, activation.
class CustomerDetailsScreen extends StatelessWidget {
  final String uid;
  const CustomerDetailsScreen({super.key, required this.uid});

  static Future<void> open(BuildContext context, String uid) {
    return UiHelpers.push(
      context,
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<UsersCubit>()),
          BlocProvider.value(value: context.read<AccountActionsCubit>()),
          BlocProvider.value(value: context.read<OrderActionsCubit>()),
          BlocProvider(create: (_) => sl<PaymentsCubit>()..watch(uid)),
          BlocProvider(create: (_) => sl<OrdersCubit>()..watch(CustomerOrdersQuery(uid))),
        ],
        child: CustomerDetailsScreen(uid: uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.select<UsersCubit, UserEntity?>((c) => c.state.byId(uid));
    if (customer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(icon: Icons.person_off_outlined, title: 'العميل غير موجود'),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(customer.name),
          bottom: const TabBar(
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            tabs: [Tab(text: 'الطلبات'), Tab(text: 'المدفوعات')],
          ),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(child: _ProfileHeader(customer: customer)),
          ],
          body: TabBarView(
            children: [
              _CustomerOrdersTab(),
              ListView(padding: const EdgeInsets.all(12), children: const [PaymentsList()]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserEntity customer;
  const _ProfileHeader({required this.customer});

  Future<void> _toggleActive(BuildContext context) async {
    final cubit = context.read<AccountActionsCubit>();
    final deactivate = customer.isActive;
    final ok = await UiHelpers.confirm(
      context,
      title: deactivate ? 'إيقاف الحساب' : 'تفعيل الحساب',
      message: deactivate
          ? 'لن يتمكن ${customer.name} من تسجيل الدخول حتى يتم التفعيل مرة أخرى.'
          : 'سيتمكن ${customer.name} من تسجيل الدخول مرة أخرى.',
      confirmLabel: deactivate ? 'إيقاف' : 'تفعيل',
      destructive: deactivate,
    );
    if (ok) cubit.setActive(customer, !deactivate);
  }

  @override
  Widget build(BuildContext context) {
    final owes = customer.balance > 0;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  UserAvatar(initial: customer.initial, radius: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                        Text(customer.phone,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(color: AppColors.textSecondary)),
                        Text(customer.email,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'الرصيد المستحق',
                value: FormatUtils.currency(customer.balance),
                valueColor: owes ? AppColors.error : AppColors.success,
                bold: true,
              ),
              InfoRow(
                icon: Icons.event_outlined,
                label: 'تاريخ التسجيل',
                value: FormatUtils.date(customer.createdAt),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: customer.isActive ? AppColors.error : AppColors.success,
                      ),
                      onPressed: () => _toggleActive(context),
                      icon: Icon(customer.isActive ? Icons.block : Icons.check_circle_outline),
                      label: Text(customer.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: owes ? () => RecordPaymentSheet.show(context, customer) : null,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('تسجيل دفعة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerOrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        if (state.status == LoadStatus.loading) return const LoadingView();
        if (state.status == LoadStatus.error) {
          return ErrorView(message: state.error ?? 'تعذر تحميل الطلبات');
        }
        if (state.orders.isEmpty) {
          return const EmptyView(icon: Icons.receipt_long_outlined, title: 'لا توجد طلبات لهذا العميل');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: state.orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => OrderCard(
            order: state.orders[i],
            showCustomer: false,
            onTap: () => OrderDetailsScreen.open(context, state.orders[i].id, isAdmin: true),
          ),
        );
      },
    );
  }
}
