import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/logout_button.dart';
import '../../../orders/presentation/screens/order_details_screen.dart';
import '../../../orders/presentation/widgets/order_card.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../cubit/dashboard_cubit.dart';

/// Admin home. [onOpenOrders] switches to the orders tab with a filter;
/// [onOpenTab] switches to any tab index.
class DashboardScreen extends StatelessWidget {
  final void Function(String? status) onOpenOrders;
  final void Function(int index) onOpenTab;

  const DashboardScreen({super.key, required this.onOpenOrders, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthCubit, String>((c) => c.state.user?.name ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم'), actions: const [LogoutButton()]),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.stats == null) {
            if (state.status == LoadStatus.error) {
              return ErrorView(
                message: state.error ?? 'تعذر تحميل الإحصائيات',
                onRetry: context.read<DashboardCubit>().watch,
              );
            }
            return const LoadingView();
          }
          final s = state.stats!;
          return LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth > 720;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _WelcomeCard(name: name, stats: s),
                const SizedBox(height: 20),
                const SectionTitle('نظرة سريعة', icon: Icons.insights_outlined),
                GridView.count(
                  crossAxisCount: wide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: wide ? 2.4 : 1.9,
                  children: [
                    StatCard(
                      title: 'طلبات منتظرة',
                      value: '${s.count(OrderStatus.pending)}',
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.statusPending,
                      onTap: () => onOpenOrders(OrderStatus.pending),
                    ),
                    StatCard(
                      title: 'جارٍ التنفيذ',
                      value: '${s.count(OrderStatus.preparing)}',
                      icon: Icons.engineering_rounded,
                      color: AppColors.statusPreparing,
                      onTap: () => onOpenOrders(OrderStatus.preparing),
                    ),
                    StatCard(
                      title: 'طلبات مكتملة',
                      value: '${s.count(OrderStatus.completed)}',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.statusCompleted,
                      onTap: () => onOpenOrders(OrderStatus.completed),
                    ),
                    StatCard(
                      title: 'طلبات اليوم',
                      value: '${s.todayOrders}',
                      icon: Icons.today_rounded,
                      color: AppColors.info,
                      onTap: () => onOpenOrders(null),
                    ),
                    StatCard(
                      title: 'المنتجات المعروضة',
                      value: '${s.activeProducts}',
                      icon: Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      onTap: () => onOpenTab(1),
                    ),
                    StatCard(
                      title: 'نفدت الكمية',
                      value: '${s.outOfStockProducts}',
                      icon: Icons.remove_shopping_cart_outlined,
                      color: AppColors.error,
                      onTap: () => onOpenTab(1),
                    ),
                    StatCard(
                      title: 'العملاء',
                      value: '${s.totalCustomers}',
                      icon: Icons.people_alt_rounded,
                      color: AppColors.secondaryDark,
                      onTap: () => onOpenTab(3),
                    ),
                    StatCard(
                      title: 'عملاء عليهم مستحقات',
                      value: '${s.customersWithDebt}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.warning,
                      onTap: () => onOpenTab(3),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _WeeklySalesChart(stats: s)),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _StatusPieChart(stats: s)),
                    ],
                  )
                else ...[
                  _WeeklySalesChart(stats: s),
                  const SizedBox(height: 12),
                  _StatusPieChart(stats: s),
                ],
                if (s.lowStockProducts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SectionTitle(
                    'تنبيهات المخزون',
                    icon: Icons.warning_amber_rounded,
                    trailing: TextButton(onPressed: () => onOpenTab(1), child: const Text('عرض المنتجات')),
                  ),
                  Card(
                    child: Column(
                      children: [
                        for (final p in s.lowStockProducts.take(6))
                          ListTile(
                            leading: ProductImage(url: p.imageUrl, width: 40, height: 40, radius: 8, iconSize: 18),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            trailing: Text(
                              p.isOutOfStock ? 'نفد' : 'متبقي ${p.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: p.isOutOfStock ? AppColors.error : AppColors.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (s.recentOrders.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SectionTitle(
                    'أحدث الطلبات',
                    icon: Icons.receipt_long_outlined,
                    trailing: TextButton(onPressed: () => onOpenOrders(null), child: const Text('عرض الكل')),
                  ),
                  for (final o in s.recentOrders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OrderCard(
                        order: o,
                        onTap: () => OrderDetailsScreen.open(context, o.id, isAdmin: true),
                      ),
                    ),
                ],
              ],
            );
          });
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  final DashboardStats stats;
  const _WelcomeCard({required this.name, required this.stats});

  @override
  Widget build(BuildContext context) {
    Widget metric(String label, String value, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مرحبًا، $name 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(
            DateFormat('EEEE d MMMM yyyy', 'ar').format(DateTime.now()),
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 24),
          Row(
            children: [
              metric('مبيعات اليوم', FormatUtils.currency(stats.todaySales), AppColors.primary),
              metric('إجمالي المبيعات', FormatUtils.currency(stats.totalSales), AppColors.success),
              metric('المستحقات', FormatUtils.currency(stats.totalOutstanding), AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklySalesChart extends StatelessWidget {
  final DashboardStats stats;
  const _WeeklySalesChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final values = stats.last7DaysSales;
    final maxY = values.fold<double>(0, (m, v) => v > m ? v : m);
    final today = DateTime.now();
    final dayFmt = DateFormat('E', 'ar');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('مبيعات آخر 7 أيام', icon: Icons.bar_chart_rounded),
            SizedBox(
              height: 200,
              child: maxY == 0
                  ? const Center(
                      child: Text('لا توجد مبيعات في آخر 7 أيام',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                    )
                  : BarChart(
                      BarChartData(
                        maxY: maxY * 1.2,
                        alignment: BarChartAlignment.spaceAround,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 4,
                          getDrawingHorizontalLine: (_) =>
                              const FlLine(color: AppColors.border, strokeWidth: 1),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => AppColors.textPrimary,
                            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                              FormatUtils.currency(rod.toY),
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, meta) {
                                final day = today.subtract(Duration(days: 6 - v.toInt()));
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    v.toInt() == 6 ? 'اليوم' : dayFmt.format(day),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < values.length; i++)
                            BarChartGroupData(x: i, barRods: [
                              BarChartRodData(
                                toY: values[i],
                                width: 18,
                                color: i == 6 ? AppColors.secondary : AppColors.primary,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ]),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final DashboardStats stats;
  const _StatusPieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = OrderStatus.all.where((s) => stats.count(s) > 0).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('توزيع الطلبات (${stats.totalOrders})', icon: Icons.pie_chart_outline),
            if (entries.isEmpty)
              const SizedBox(
                height: 120,
                child: Center(
                  child: Text('لا توجد طلبات بعد',
                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                ),
              )
            else
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 32,
                        sectionsSpace: 2,
                        sections: [
                          for (final s in entries)
                            PieChartSectionData(
                              value: stats.count(s).toDouble(),
                              color: AppColors.forOrderStatus(s),
                              radius: 30,
                              title: '${stats.count(s)}',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in OrderStatus.all)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.forOrderStatus(s),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(FormatUtils.orderStatus(s),
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                Text('${stats.count(s)}',
                                    style: const TextStyle(fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
