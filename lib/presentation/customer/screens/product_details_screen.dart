import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/product_model.dart';
import '../providers/cart_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  ProductModel get product => widget.product;
  double get lineTotal => product.price * _quantity;

  void _increment() {
    if (_quantity < product.quantity) setState(() => _quantity++);
  }

  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _addToCart() {
    final cart = context.read<CartProvider>();
    // Remove existing then add with new quantity
    cart.removeProduct(product.id);
    for (int i = 0; i < _quantity; i++) {
      if (i == 0) {
        cart.addProduct(product);
      } else {
        cart.increment(product.id);
      }
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة ${product.name} (×$_quantity) للسلة ✓'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.isOutOfStock;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        child: const Icon(Icons.inventory_2_outlined,
                            size: 80, color: AppColors.primaryLight),
                      ),
                    )
                  : Container(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      child: const Icon(Icons.inventory_2_outlined,
                          size: 80, color: AppColors.primaryLight),
                    ),
            ),
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        FormatUtils.currency(product.price),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  // Stock info
                  Row(
                    children: [
                      Icon(
                        isOutOfStock
                            ? Icons.remove_circle_outline
                            : Icons.check_circle_outline,
                        size: 16,
                        color: isOutOfStock ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOutOfStock
                            ? 'نفدت الكمية'
                            : 'متاح: ${product.quantity} قطعة',
                        style: TextStyle(
                          color: isOutOfStock
                              ? AppColors.error
                              : AppColors.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'الوصف',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Quantity Selector
                  if (!isOutOfStock) ...[
                    const Text(
                      'الكمية',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Decrement
                        _QuantityBtn(
                          icon: Icons.remove,
                          onTap: _decrement,
                          enabled: _quantity > 1,
                        ),
                        const SizedBox(width: 20),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Increment
                        _QuantityBtn(
                          icon: Icons.add,
                          onTap: _increment,
                          enabled: _quantity < product.quantity,
                        ),
                        const Spacer(),
                        // Live total
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('الإجمالي',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(
                              FormatUtils.currency(lineTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'إضافة للسلة',
                      icon: Icons.shopping_cart_outlined,
                      onPressed: _addToCart,
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_circle_outline,
                              color: AppColors.error),
                          SizedBox(width: 8),
                          Text(
                            'هذا المنتج غير متاح حالياً',
                            style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _QuantityBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.secondary.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? AppColors.secondary.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.secondary : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}
