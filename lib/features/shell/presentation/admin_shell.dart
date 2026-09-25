import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/widgets/submission_listener.dart';
import '../../accounts/presentation/cubit/account_actions_cubit.dart';
import '../../accounts/presentation/cubit/users_cubit.dart';
import '../../accounts/presentation/screens/customers_screen.dart';
import '../../accounts/presentation/screens/staff_screen.dart';
import '../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../orders/domain/usecases/order_usecases.dart';
import '../../orders/presentation/cubit/order_actions_cubit.dart';
import '../../orders/presentation/cubit/orders_cubit.dart';
import '../../orders/presentation/screens/admin_orders_screen.dart';
import '../../products/presentation/cubit/product_actions_cubit.dart';
import '../../products/presentation/cubit/products_cubit.dart';
import '../../products/presentation/screens/admin_products_screen.dart';

/// Admin area: Dashboard · Products · Orders · Customers · Staff.
///
/// Provides the admin-wide Cubits once so every tab (and every pushed
/// details page) shares the same live data.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<DashboardCubit>()..watch()),
        BlocProvider(create: (_) => sl<ProductsCubit>()..watch(activeOnly: false)),
        BlocProvider(create: (_) => sl<OrdersCubit>()..watch(const AllOrdersQuery())),
        BlocProvider(create: (_) => sl<UsersCubit>()..watchCustomers()),
        BlocProvider(create: (_) => sl<ProductActionsCubit>()),
        BlocProvider(create: (_) => sl<OrderActionsCubit>()),
        BlocProvider(create: (_) => sl<AccountActionsCubit>()),
      ],
      child: const SubmissionListener<ProductActionsCubit>(
        child: SubmissionListener<OrderActionsCubit>(
          child: SubmissionListener<AccountActionsCubit>(
            child: _AdminTabs(),
          ),
        ),
      ),
    );
  }
}

class _AdminTabs extends StatefulWidget {
  const _AdminTabs();

  @override
  State<_AdminTabs> createState() => _AdminTabsState();
}

class _AdminTabsState extends State<_AdminTabs> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pending = context.select<OrdersCubit, int>((c) => c.state.countOf('pending'));

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            onOpenTab: _go,
            onOpenOrders: (status) {
              context.read<OrdersCubit>().setStatusFilter(status);
              _go(2);
            },
          ),
          const AdminProductsScreen(),
          const AdminOrdersScreen(),
          const CustomersScreen(),
          const StaffScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFD5DCE6))),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard),
              label: 'الرئيسية',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'المنتجات',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pending > 0,
                label: Text('$pending'),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'الطلبات',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'العملاء',
            ),
            const NavigationDestination(
              icon: Icon(Icons.badge_outlined),
              selectedIcon: Icon(Icons.badge),
              label: 'الفريق',
            ),
          ],
        ),
      ),
    );
  }
}
