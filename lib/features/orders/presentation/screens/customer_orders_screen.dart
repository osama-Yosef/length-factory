import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/state_views.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_card.dart';
import 'order_details_screen.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state.status == LoadStatus.loading) return const LoadingView();
          if (state.status == LoadStatus.error) {
            return ErrorView(
              message: state.error ?? 'تعذر تحميل الطلبات',
              onRetry: context.read<OrdersCubit>().retry,
            );
          }
          if (state.orders.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد طلبات بعد',
              subtitle: 'تصفّح المنتجات وأضفها للسلة لإنشاء أول طلب',
            );
          }
          final orders = state.visible;
          return Column(
            children: [
              OrderStatusFilterBar(
                selected: state.statusFilter,
                countOf: state.countOf,
                onSelected: context.read<OrdersCubit>().setStatusFilter,
              ),
              Expanded(
                child: orders.isEmpty
                    ? const EmptyView(icon: Icons.filter_alt_off_outlined, title: 'لا توجد طلبات بهذه الحالة')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => OrderCard(
                          order: orders[i],
                          showCustomer: false,
                          onTap: () => OrderDetailsScreen.open(context, orders[i].id),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
