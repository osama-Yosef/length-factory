import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../cubit/checkout_cubit.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CheckoutCubit>(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final user = context.read<AuthCubit>().state.user;
    final cart = context.read<CartCubit>().state;
    if (user == null || cart.isEmpty) return;
    context.read<CheckoutCubit>().placeOrder(customer: user, items: cart.items, note: _noteCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutSuccess) context.read<CartCubit>().clear();
        if (state is CheckoutFailure) UiHelpers.showSnack(context, state.message, isError: true);
      },
      builder: (context, state) {
        if (state is CheckoutSuccess) return _SuccessView(state: state);
        return _review(context, state is CheckoutSubmitting);
      },
    );
  }

  Widget _review(BuildContext context, bool submitting) {
    final user = context.watch<AuthCubit>().state.user;
    final cart = context.watch<CartCubit>().state;
    final balance = user?.balance ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة الطلب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SectionTitle('بيانات العميل', icon: Icons.person_outline),
                  InfoRow(label: 'الاسم', value: user?.name ?? ''),
                  InfoRow(label: 'الهاتف', value: user?.phone ?? ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle('المنتجات (${cart.totalQuantity} قطعة)', icon: Icons.inventory_2_outlined),
                  for (final item in cart.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${item.product.name}  × ${item.quantity}',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Text(FormatUtils.currency(item.lineTotal),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  const Divider(height: 22),
                  InfoRow(
                    label: 'إجمالي الطلب',
                    value: FormatUtils.currency(cart.totalPrice),
                    valueColor: AppColors.primary,
                    bold: true,
                  ),
                  InfoRow(label: 'رصيدك الحالي', value: FormatUtils.currency(balance)),
                  InfoRow(
                    label: 'الرصيد بعد الطلب',
                    value: FormatUtils.currency(balance + cart.totalPrice),
                    valueColor: AppColors.error,
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'ملاحظات على الطلب (اختياري)',
              hintText: 'مثال: مقاسات خاصة، موعد الاستلام...',
              prefixIcon: Icon(Icons.edit_note),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ستُضاف قيمة الطلب إلى رصيدك المستحق، ويمكنك السداد لاحقًا لدى الإدارة.',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: 'تأكيد الطلب نهائيًا',
            icon: Icons.check_circle_outline,
            color: AppColors.secondary,
            isLoading: submitting,
            onPressed: cart.isEmpty ? null : _confirm,
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final CheckoutSuccess state;
  const _SuccessView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 60),
                ),
                const SizedBox(height: 18),
                const Text('تم تأكيد طلبك بنجاح!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('سيبدأ فريق الإنتاج في تجهيز طلبك قريبًا',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        InfoRow(label: 'رقم الطلب', value: '#${state.order.orderNumber}', bold: true),
                        InfoRow(
                          label: 'قيمة الطلب',
                          value: FormatUtils.currency(state.order.totalPrice),
                          valueColor: AppColors.primary,
                        ),
                        InfoRow(
                          label: 'الرصيد المستحق الآن',
                          value: FormatUtils.currency(state.newBalance),
                          valueColor: AppColors.error,
                        ),
                        InfoRow(label: 'حالة الطلب', value: FormatUtils.orderStatus(state.order.status)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'حسنًا',
                  color: AppColors.success,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
