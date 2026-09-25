import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../orders/presentation/screens/checkout_screen.dart';
import '../../domain/entities/cart_item.dart';
import '../cubit/cart_cubit.dart';

class CartScreen extends StatelessWidget {
  /// Called from the empty state to jump back to the store tab.
  final VoidCallback? onBrowse;

  const CartScreen({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('سلة الشراء'),
            actions: [
              if (!cart.isEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () async {
                    final ok = await UiHelpers.confirm(
                      context,
                      title: 'تفريغ السلة',
                      message: 'هل تريد إزالة كل المنتجات من السلة؟',
                      confirmLabel: 'تفريغ',
                      destructive: true,
                    );
                    if (ok && context.mounted) context.read<CartCubit>().clear();
                  },
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('تفريغ'),
                ),
            ],
          ),
          body: cart.isEmpty
              ? EmptyView(
                  icon: Icons.shopping_cart_outlined,
                  title: 'السلة فارغة',
                  subtitle: 'أضف منتجات من المتجر لإتمام الطلب',
                  action: onBrowse == null
                      ? null
                      : ElevatedButton.icon(
                          onPressed: onBrowse,
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('تصفح المنتجات'),
                        ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CartItemTile(item: cart.items[i]),
                ),
          bottomNavigationBar: cart.isEmpty ? null : _CartSummary(cart: cart),
        );
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    final atMax = item.quantity >= item.product.quantity;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProductImage(url: item.product.imageUrl, width: 68, height: 68),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '${FormatUtils.currency(item.product.price)} للوحدة',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QuantityButton(
                        icon: item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                        onTap: () => cubit.decrement(item.product.id),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      ),
                      QuantityButton(
                        icon: Icons.add,
                        onTap: atMax ? null : () => cubit.increment(item.product.id),
                      ),
                      const Spacer(),
                      Text(
                        FormatUtils.currency(item.lineTotal),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  if (atMax)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'وصلت للحد الأقصى المتاح في المخزون',
                        style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w700),
                      ),
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

class _CartSummary extends StatelessWidget {
  final CartState cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoRow(label: 'عدد القطع', value: '${cart.totalQuantity}'),
            InfoRow(
              label: 'إجمالي الفاتورة',
              value: FormatUtils.currency(cart.totalPrice),
              valueColor: AppColors.primary,
              bold: true,
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'متابعة لتأكيد الطلب',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => UiHelpers.push(context, const CheckoutScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
