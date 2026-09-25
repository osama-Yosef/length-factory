import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../products/domain/entities/product_entity.dart';

/// All admin KPIs, computed purely from the live lists.
class DashboardStats extends Equatable {
  final int activeProducts;
  final int hiddenProducts;
  final int outOfStockProducts;
  final List<ProductEntity> lowStockProducts;

  final int totalCustomers;
  final int customersWithDebt;
  final double totalOutstanding;

  final int totalOrders;
  final Map<String, int> ordersByStatus;
  final int todayOrders;
  final double totalSales; // non-cancelled orders
  final double todaySales;

  /// Sales of the last 7 days, oldest first (index 6 = today).
  final List<double> last7DaysSales;
  final List<OrderEntity> recentOrders;

  const DashboardStats({
    required this.activeProducts,
    required this.hiddenProducts,
    required this.outOfStockProducts,
    required this.lowStockProducts,
    required this.totalCustomers,
    required this.customersWithDebt,
    required this.totalOutstanding,
    required this.totalOrders,
    required this.ordersByStatus,
    required this.todayOrders,
    required this.totalSales,
    required this.todaySales,
    required this.last7DaysSales,
    required this.recentOrders,
  });

  int count(String status) => ordersByStatus[status] ?? 0;

  factory DashboardStats.compute({
    required List<ProductEntity> products,
    required List<UserEntity> customers,
    required List<OrderEntity> orders,
    DateTime? now,
  }) {
    final today = _day(now ?? DateTime.now());
    final active = products.where((p) => p.isActive).toList();

    final byStatus = {for (final s in OrderStatus.all) s: 0};
    var totalSales = 0.0, todaySales = 0.0;
    var todayOrders = 0;
    final week = List<double>.filled(7, 0);

    for (final o in orders) {
      byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
      final day = _day(o.createdAt);
      final isToday = day == today;
      if (isToday) todayOrders++;
      if (o.isCancelled) continue;
      totalSales += o.totalPrice;
      if (isToday) todaySales += o.totalPrice;
      final diff = today.difference(day).inDays;
      if (diff >= 0 && diff < 7) week[6 - diff] += o.totalPrice;
    }

    final lowStock = active.where((p) => p.isLowStock || p.isOutOfStock).toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));

    final sortedOrders = [...orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DashboardStats(
      activeProducts: active.length,
      hiddenProducts: products.length - active.length,
      outOfStockProducts: active.where((p) => p.isOutOfStock).length,
      lowStockProducts: lowStock,
      totalCustomers: customers.length,
      customersWithDebt: customers.where((c) => c.balance > 0).length,
      totalOutstanding: customers.fold(0, (s, c) => s + (c.balance > 0 ? c.balance : 0)),
      totalOrders: orders.length,
      ordersByStatus: byStatus,
      todayOrders: todayOrders,
      totalSales: totalSales,
      todaySales: todaySales,
      last7DaysSales: week,
      recentOrders: sortedOrders.take(5).toList(),
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  List<Object?> get props => [
        activeProducts,
        hiddenProducts,
        outOfStockProducts,
        lowStockProducts,
        totalCustomers,
        customersWithDebt,
        totalOutstanding,
        totalOrders,
        ordersByStatus,
        todayOrders,
        totalSales,
        todaySales,
        last7DaysSales,
        recentOrders,
      ];
}
