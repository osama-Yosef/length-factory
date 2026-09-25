import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../domain/entities/product_entity.dart';
import '../cubit/products_cubit.dart';
import '../widgets/stock_badge.dart';

/// Live product details (stock/price refresh in real time).
class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  static Future<void> open(BuildContext context, String productId) {
    return UiHelpers.push(
      context,
      BlocProvider.value(
        value: context.read<ProductsCubit>(),
        child: ProductDetailsScreen(productId: productId),
      ),
    );
  }

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  void _addToCart(ProductEntity product, int alreadyInCart) {
    final cart = context.read<CartCubit>();
    final total = cart.add(product, quantity: _quantity);
    final added = total - alreadyInCart;
    UiHelpers.showSnack(
      context,
      added > 0
          ? 'تمت إضافة ${product.name} (×$added) للسلة'
          : 'الكمية المتاحة من ${product.name} موجودة بالفعل في السلة',
      isError: added <= 0,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final product = context.select<ProductsCubit, ProductEntity?>((c) => c.state.byId(widget.productId));
    final inCart = context.select<CartCubit, int>((c) => c.state.quantityOf(widget.productId));

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(icon: Icons.inventory_2_outlined, title: 'المنتج لم يعد متاحًا'),
      );
    }

    final available = (product.quantity - inCart).clamp(0, product.quantity);
    if (_quantity > available && available > 0) _quantity = available;
    final canAdd = available > 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: ProductImage(url: product.imageUrl, radius: 0, iconSize: 80),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        FormatUtils.currency(product.price),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      StockBadge(product: product),
                    ],
                  ),
                  if (inCart > 0) ...[
                    const SizedBox(height: 10),
                    Text('لديك $inCart في السلة',
                        style: const TextStyle(color: AppColors.secondaryDark, fontWeight: FontWeight.w800)),
                  ],
                  if (product.description.isNotEmpty) ...[
                    const Divider(height: 32),
                    const SectionTitle('الوصف', icon: Icons.description_outlined),
                    Text(product.description,
                        style: const TextStyle(color: AppColors.textPrimary, height: 1.7, fontSize: 15)),
                  ],
                  const Divider(height: 32),
                  if (canAdd) ...[
                    const SectionTitle('الكمية', icon: Icons.format_list_numbered),
                    Row(
                      children: [
                        QuantityButton(
                          icon: Icons.remove,
                          size: 44,
                          onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text('$_quantity',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        ),
                        QuantityButton(
                          icon: Icons.add,
                          size: 44,
                          onTap: _quantity < available ? () => setState(() => _quantity++) : null,
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('الإجمالي',
                                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            Text(
                              FormatUtils.currency(product.price * _quantity),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        product.isOutOfStock
                            ? 'هذا المنتج غير متاح حاليًا'
                            : 'كل الكمية المتاحة موجودة بالفعل في سلتك',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: canAdd
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryButton(
                  label: 'إضافة للسلة',
                  icon: Icons.add_shopping_cart,
                  color: AppColors.secondary,
                  onPressed: () => _addToCart(product, inCart),
                ),
              ),
            )
          : null,
    );
  }
}
