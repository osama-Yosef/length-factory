import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../domain/entities/product_entity.dart';
import '../cubit/products_cubit.dart';
import 'product_details_screen.dart';

class StorefrontScreen extends StatelessWidget {
  const StorefrontScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: AppSearchField(
              hint: 'ابحث عن منتج...',
              onChanged: context.read<ProductsCubit>().search,
            ),
          ),
        ),
      ),
      body: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.error:
              return ErrorView(
                message: state.error ?? 'تعذر تحميل المنتجات',
                onRetry: context.read<ProductsCubit>().retry,
              );
            case LoadStatus.loaded:
              final products = state.visible;
              if (products.isEmpty) {
                return EmptyView(
                  icon: Icons.inventory_2_outlined,
                  title: state.query.isNotEmpty
                      ? 'لا توجد نتائج لـ "${state.query}"'
                      : 'لا توجد منتجات متاحة حاليًا',
                );
              }
              return LayoutBuilder(
                builder: (context, c) {
                  final columns = (c.maxWidth / 190).floor().clamp(2, 6);
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: 0.66,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) => _ProductCard(product: products[i]),
                  );
                },
              );
          }
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final inCart = context.select<CartCubit, int>((c) => c.state.quantityOf(product.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ProductDetailsScreen.open(context, product.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: product.imageUrl, radius: 0, iconSize: 40),
                  if (product.isOutOfStock)
                    Container(
                      color: Colors.white.withValues(alpha: 0.75),
                      alignment: Alignment.center,
                      child: const Text(
                        'نفدت الكمية',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                  if (product.isLowStock)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Text('متبقي ${product.quantity}',
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.warning)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          FormatUtils.currency(product.price),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!product.isOutOfStock) _AddButton(product: product, inCart: inCart),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final ProductEntity product;
  final int inCart;

  const _AddButton({required this.product, required this.inCart});

  @override
  Widget build(BuildContext context) {
    final atMax = inCart >= product.quantity;
    return Material(
      color: inCart > 0 ? AppColors.secondary : AppColors.secondarySoft,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: atMax
            ? () => UiHelpers.showSnack(context, 'وصلت للحد الأقصى المتاح من "${product.name}"', isError: true)
            : () {
                context.read<CartCubit>().add(product);
                UiHelpers.showSnack(context, 'تمت إضافة "${product.name}" للسلة');
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                inCart > 0 ? Icons.shopping_cart : Icons.add_shopping_cart_outlined,
                size: 18,
                color: inCart > 0 ? Colors.white : AppColors.secondaryDark,
              ),
              if (inCart > 0) ...[
                const SizedBox(width: 4),
                Text('$inCart',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
