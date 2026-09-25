import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/submission_listener.dart';
import '../../accounts/presentation/cubit/account_actions_cubit.dart';
import '../../accounts/presentation/cubit/payments_cubit.dart';
import '../../accounts/presentation/screens/profile_screen.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../cart/presentation/cubit/cart_cubit.dart';
import '../../cart/presentation/screens/cart_screen.dart';
import '../../orders/domain/usecases/order_usecases.dart';
import '../../orders/presentation/cubit/orders_cubit.dart';
import '../../orders/presentation/screens/customer_orders_screen.dart';
import '../../products/presentation/cubit/products_cubit.dart';
import '../../products/presentation/screens/storefront_screen.dart';

/// Customer area: Store · Cart · My Orders · Account.
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthCubit>().state.user?.uid ?? '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ProductsCubit>()..watch(activeOnly: true)),
        BlocProvider(create: (_) => sl<OrdersCubit>()..watch(CustomerOrdersQuery(uid))),
        BlocProvider(create: (_) => sl<PaymentsCubit>()..watch(uid)),
        BlocProvider(create: (_) => sl<AccountActionsCubit>()),
      ],
      child: SubmissionListener<AccountActionsCubit>(
        // Keep cart prices/stock in sync with the live catalog.
        child: BlocListener<ProductsCubit, ProductsState>(
          listenWhen: (p, c) => c.status == LoadStatus.loaded && p.products != c.products,
          listener: (context, state) => context.read<CartCubit>().syncWithCatalog(state.products),
          child: const _CustomerTabs(),
        ),
      ),
    );
  }
}

class _CustomerTabs extends StatefulWidget {
  const _CustomerTabs();

  @override
  State<_CustomerTabs> createState() => _CustomerTabsState();
}

class _CustomerTabsState extends State<_CustomerTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<CartCubit, int>((c) => c.state.totalQuantity);
    final activeOrders = context.select<OrdersCubit, int>(
      (c) => c.state.orders.where((o) => o.isActive).length,
    );

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const StorefrontScreen(),
          CartScreen(onBrowse: () => setState(() => _index = 0)),
          const CustomerOrdersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'المتجر',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                backgroundColor: AppColors.secondary,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartCount > 0,
                backgroundColor: AppColors.secondary,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'السلة',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: activeOrders > 0,
                label: Text('$activeOrders'),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'طلباتي',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}
