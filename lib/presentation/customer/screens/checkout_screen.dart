import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_model.dart' show OrderItemModel;
import '../../../data/repositories/order_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _repo = OrderRepository();
  bool _isLoading = false;
  String? _errorMessage;

  // After success
  String? _orderId;
  String? _orderNumber;
  double? _newBalance;

  Future<void> _confirmOrder() async {
    final cart = context.read<CartProvider>();
    final user = context.read<AuthProvider>().currentUser!;

    if (cart.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderNumber = _generateOrderNumber();
      final items = cart.items
          .map((cartItem) => OrderItemModel(
                productId: cartItem.product.id,
                productName: cartItem.product.name,
                productImage: cartItem.product.imageUrl,
                unitPrice: cartItem.product.price,
                quantity: cartItem.quantity,
              ))
          .toList();

      final order = OrderModel(
        id: '',
        orderNumber: orderNumber,
        customerId: user.uid,
        customerName: user.name,
        customerPhone: user.phone,
        items: items,
        totalPrice: cart.totalPrice,
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.unpaid,
        createdAt: DateTime.now(),
      );

      final orderId = await _repo.placeOrder(order);

      // Calculate new balance for display
      final newBalance = user.balance + cart.totalPrice;

      setState(() {
        _orderId = orderId;
        _orderNumber = orderNumber;
        _newBalance = newBalance;
      });

      cart.clear();
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateOrderNumber() {
    const uuid = Uuid();
    return uuid.v4().substring(0, 8).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: _orderId != null
            ? _SuccessView(
                orderNumber: _orderNumber!,
                total: _newBalance! - (user?.balance ?? 0),
                newBalance: _newBalance!,
                onDone: () => Navigator.pop(context),
              )
            : ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'مراجعة الطلب',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),

                  // Customer Info
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'الاسم',
                    value: user?.name ?? '',
                  ),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'الهاتف',
                    value: user?.phone ?? '',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Items Summary
                  const Text('المنتجات',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 6, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  '${item.product.name} × ${item.quantity}'),
                            ),
                            Text(
                              FormatUtils.currency(item.lineTotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),

                  const Divider(height: 24),

                  // Totals
                  _InfoRow(
                    icon: Icons.receipt_outlined,
                    label: 'إجمالي الطلب',
                    value: FormatUtils.currency(cart.totalPrice),
                    valueStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                      fontSize: 16,
                    ),
                  ),
                  _InfoRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'الرصيد الحالي',
                    value: FormatUtils.currency(user?.balance ?? 0),
                  ),
                  _InfoRow(
                    icon: Icons.trending_up_outlined,
                    label: 'الرصيد بعد الطلب',
                    value: FormatUtils.currency(
                        (user?.balance ?? 0) + cart.totalPrice),
                    valueStyle: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.info, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سيتم إضافة قيمة الطلب لرصيدك المستحق. يمكن السداد لاحقًا.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  PrimaryButton(
                    label: 'تأكيد الطلب نهائيًا',
                    icon: Icons.check_circle_outline,
                    isLoading: _isLoading,
                    onPressed: _confirmOrder,
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success View ───────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String orderNumber;
  final double total;
  final double newBalance;
  final VoidCallback onDone;

  const _SuccessView({
    required this.orderNumber,
    required this.total,
    required this.newBalance,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 48),
        ),
        const SizedBox(height: 20),
        const Text(
          'تم تأكيد طلبك! ✓',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        _SuccessRow(label: 'رقم الطلب', value: '#$orderNumber'),
        _SuccessRow(
            label: 'قيمة الطلب',
            value: FormatUtils.currency(total),
            valueColor: AppColors.secondary),
        _SuccessRow(
            label: 'الرصيد المستحق',
            value: FormatUtils.currency(newBalance),
            valueColor: AppColors.error),
        _SuccessRow(label: 'حالة الطلب', value: 'قيد الانتظار'),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حسنًا',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _SuccessRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SuccessRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
