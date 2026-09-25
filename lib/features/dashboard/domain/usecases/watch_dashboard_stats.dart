import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/stream_utils.dart';
import '../../../accounts/domain/repositories/accounts_repository.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../entities/dashboard_stats.dart';

/// Combines products + customers + orders into live [DashboardStats].
class WatchDashboardStatsUseCase extends StreamUseCase<DashboardStats, NoParams> {
  final ProductRepository _products;
  final AccountsRepository _accounts;
  final OrderRepository _orders;

  WatchDashboardStatsUseCase(this._products, this._accounts, this._orders);

  @override
  Stream<DashboardStats> call(NoParams params) => combineLatest3(
        _products.watchProducts(activeOnly: false),
        _accounts.watchCustomers(),
        _orders.watchAllOrders(),
        (products, customers, orders) => DashboardStats.compute(
          products: products,
          customers: customers,
          orders: orders,
        ),
      );
}
