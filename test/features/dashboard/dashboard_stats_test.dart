import 'package:flutter_test/flutter_test.dart';
import 'package:length_factory/features/dashboard/domain/entities/dashboard_stats.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('DashboardStats.compute aggregates products, customers and orders', () {
    final now = DateTime(2026, 9, 25, 12);
    final stats = DashboardStats.compute(
      now: now,
      products: [
        product(id: 'a', quantity: 50),
        product(id: 'b', quantity: 3), // low
        product(id: 'c', quantity: 0), // out
        product(id: 'd', isActive: false),
      ],
      customers: [user(uid: 'x', balance: 500), user(uid: 'y')],
      orders: [
        order(id: '1', total: 100, createdAt: now),
        order(id: '2', total: 300, status: 'completed', createdAt: now.subtract(const Duration(days: 2))),
        order(id: '3', total: 999, status: 'cancelled', createdAt: now),
      ],
    );

    expect(stats.activeProducts, 3);
    expect(stats.hiddenProducts, 1);
    expect(stats.outOfStockProducts, 1);
    expect(stats.lowStockProducts.map((p) => p.id), ['c', 'b']);
    expect(stats.totalCustomers, 2);
    expect(stats.customersWithDebt, 1);
    expect(stats.totalOutstanding, 500);
    expect(stats.totalOrders, 3);
    expect(stats.todayOrders, 2);
    expect(stats.totalSales, 400); // cancelled excluded
    expect(stats.todaySales, 100);
    expect(stats.last7DaysSales[6], 100);
    expect(stats.last7DaysSales[4], 300);
    expect(stats.count('cancelled'), 1);
  });
}
