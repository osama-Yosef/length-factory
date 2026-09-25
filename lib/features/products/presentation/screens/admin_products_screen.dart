import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/product_entity.dart';
import '../cubit/product_actions_cubit.dart';
import '../cubit/products_cubit.dart';
import '../widgets/product_form_sheet.dart';
import '../widgets/stock_badge.dart';

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  static const _filters = {
    ProductFilter.all: 'الكل',
    ProductFilter.available: 'متاح',
    ProductFilter.lowStock: 'كمية محدودة',
    ProductFilter.outOfStock: 'نفد',
    ProductFilter.hidden: 'مخفي',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المنتجات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ProductFormSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
      ),
      body: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          final cubit = context.read<ProductsCubit>();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: AppSearchField(hint: 'بحث في المنتجات...', onChanged: cubit.search),
              ),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    for (final e in _filters.entries) ...[
                      ChoiceChip(
                        label: Text(e.value),
                        selected: state.filter == e.key,
                        onSelected: (_) => cubit.setFilter(e.key),
                      ),
                      const SizedBox(width: 8),
                    ],
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

  Widget _body(BuildContext context, ProductsState state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: state.error ?? 'تعذر تحميل المنتجات',
          onRetry: context.read<ProductsCubit>().retry,
        );
      case LoadStatus.loaded:
        final list = state.visible;
        if (list.isEmpty) {
          return EmptyView(
            icon: Icons.inventory_2_outlined,
            title: state.products.isEmpty ? 'لا توجد منتجات بعد' : 'لا توجد نتائج',
            action: state.products.isEmpty
                ? ElevatedButton.icon(
                    onPressed: () => ProductFormSheet.show(context),
                    icon: const Icon(Icons.add),
                    label: const Text('أضف أول منتج'),
                  )
                : null,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _AdminProductTile(product: list[i]),
        );
    }
  }
}

class _AdminProductTile extends StatelessWidget {
  final ProductEntity product;
  const _AdminProductTile({required this.product});

  Future<void> _toggleActive(BuildContext context) async {
    final cubit = context.read<ProductActionsCubit>();
    if (product.isActive) {
      final ok = await UiHelpers.confirm(
        context,
        title: 'إخفاء المنتج',
        message: 'سيختفي "${product.name}" من المتجر، وتبقى الطلبات السابقة كما هي. متابعة؟',
        confirmLabel: 'إخفاء',
        destructive: true,
        icon: Icons.visibility_off_outlined,
      );
      if (!ok) return;
    }
    cubit.setActive(product, !product.isActive);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ProductFormSheet.show(context, product: product),
        child: Opacity(
          opacity: product.isActive ? 1 : 0.7,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ProductImage(url: product.imageUrl, width: 72, height: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
                      const SizedBox(height: 2),
                      Text(
                        FormatUtils.currency(product.price),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          StockBadge(product: product),
                          if (!product.isActive)
                            const AppBadge(
                              label: 'مخفي',
                              foreground: AppColors.textSecondary,
                              background: AppColors.surfaceMuted,
                              icon: Icons.visibility_off_outlined,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'خيارات',
                  onSelected: (v) {
                    if (v == 'edit') ProductFormSheet.show(context, product: product);
                    if (v == 'toggle') _toggleActive(context);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('تعديل')),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                        leading: Icon(
                          product.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: product.isActive ? AppColors.error : AppColors.success,
                        ),
                        title: Text(product.isActive ? 'إخفاء من المتجر' : 'إعادة العرض بالمتجر'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
