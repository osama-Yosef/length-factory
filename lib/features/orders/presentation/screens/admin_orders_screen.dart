import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_card.dart';
import 'order_details_screen.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطلبات')),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          final cubit = context.read<OrdersCubit>();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: AppSearchField(
                  hint: 'بحث بالعميل، الهاتف، رقم الطلب أو المنتج...',
                  onChanged: cubit.search,
                ),
              ),
              OrderStatusFilterBar(
                selected: state.statusFilter,
                countOf: state.countOf,
                onSelected: cubit.setStatusFilter,
              ),
              Expanded(child: _body(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, OrdersState state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: state.error ?? 'تعذر تحميل الطلبات',
          onRetry: context.read<OrdersCubit>().retry,
        );
      case LoadStatus.loaded:
        final orders = state.visible;
        if (orders.isEmpty) {
          return const EmptyView(icon: Icons.receipt_long_outlined, title: 'لا توجد طلبات');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => OrderCard(
            order: orders[i],
            onTap: () => OrderDetailsScreen.open(context, orders[i].id, isAdmin: true),
          ),
        );
    }
  }
}
