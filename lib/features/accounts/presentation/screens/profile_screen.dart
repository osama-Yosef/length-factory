import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/submission_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/logout_button.dart';
import '../../domain/usecases/accounts_usecases.dart';
import '../cubit/account_actions_cubit.dart';
import '../widgets/payments_list.dart';
import '../widgets/user_avatar.dart';

/// Customer "My Account": live balance, profile edit, payment history.
/// Requires [PaymentsCubit] and [AccountActionsCubit] above it.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthCubit, UserEntity?>((c) => c.state.user);
    if (user == null) return const SizedBox.shrink();
    final owes = user.balance > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي'), actions: const [LogoutButton()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UserAvatar(initial: user.initial, radius: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        Text(user.phone,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(color: AppColors.textSecondary)),
                        Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'تعديل البيانات',
                    onPressed: () => _EditProfileSheet.show(context, user),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: owes ? AppColors.errorSoft : AppColors.successSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (owes ? AppColors.error : AppColors.success).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded,
                    size: 38, color: owes ? AppColors.error : AppColors.success),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        owes ? 'الرصيد المستحق عليك' : 'لا توجد مستحقات عليك',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      Text(
                        FormatUtils.currency(user.balance.abs()),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: owes ? AppColors.error : AppColors.success,
                        ),
                      ),
                      if (user.balance < 0)
                        const Text('رصيد دائن لصالحك',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('سجل المدفوعات', icon: Icons.receipt_outlined),
          const PaymentsList(),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserEntity user;
  const _EditProfileSheet({required this.user});

  static Future<void> show(BuildContext context, UserEntity user) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AccountActionsCubit>(),
        child: _EditProfileSheet(user: user),
      ),
    );
  }

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountActionsCubit, SubmissionState>(
      listener: (context, state) {
        if (_submitted && state is SubmissionSuccess) Navigator.of(context).pop();
      },
      builder: (context, state) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تعديل البيانات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => Validators.required(v, 'أدخل الاسم'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration:
                      const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: Validators.phone,
                ),
                if (state is SubmissionFailure) ...[
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'حفظ',
                  icon: Icons.save_outlined,
                  isLoading: state is SubmissionLoading,
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    _submitted = true;
                    context.read<AccountActionsCubit>().updateProfile(UpdateProfileParams(
                          uid: widget.user.uid,
                          name: _name.text,
                          phone: _phone.text,
                        ));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
