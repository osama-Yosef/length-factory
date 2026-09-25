import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/cubit/submission_state.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/logout_button.dart';
import '../../domain/usecases/accounts_usecases.dart';
import '../cubit/account_actions_cubit.dart';
import '../cubit/users_cubit.dart';
import '../widgets/user_avatar.dart';

/// Admin: manage Workers and Admins.
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UsersCubit>()..watchStaff(),
      child: const _StaffView(),
    );
  }
}

class _StaffView extends StatelessWidget {
  const _StaffView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فريق العمل'), actions: const [LogoutButton()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _AddStaffSheet.show(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('إضافة موظف'),
      ),
      body: BlocBuilder<UsersCubit, UsersState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.error:
              return ErrorView(
                message: state.error ?? 'تعذر تحميل فريق العمل',
                onRetry: context.read<UsersCubit>().retry,
              );
            case LoadStatus.loaded:
              if (state.users.isEmpty) {
                return const EmptyView(icon: Icons.badge_outlined, title: 'لا يوجد موظفون بعد');
              }
              final admins = state.users.where((u) => u.isAdmin).toList();
              final workers = state.users.where((u) => u.isWorker).toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                children: [
                  SectionTitle('العمال (${workers.length})', icon: Icons.engineering_outlined),
                  if (workers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('لا يوجد عمال', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  for (final u in workers) _StaffTile(user: u),
                  const SizedBox(height: 12),
                  SectionTitle('المديرون (${admins.length})', icon: Icons.admin_panel_settings_outlined),
                  for (final u in admins) _StaffTile(user: u),
                ],
              );
          }
        },
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final UserEntity user;
  const _StaffTile({required this.user});

  Future<void> _toggle(BuildContext context, bool active) async {
    final cubit = context.read<AccountActionsCubit>();
    if (!active) {
      final ok = await UiHelpers.confirm(
        context,
        title: 'إيقاف الحساب',
        message: 'لن يتمكن ${user.name} من تسجيل الدخول. متابعة؟',
        confirmLabel: 'إيقاف',
        destructive: true,
      );
      if (!ok) return;
    }
    cubit.setActive(user, active);
  }

  @override
  Widget build(BuildContext context) {
    final isMe = context.select<AuthCubit, bool>((c) => c.state.user?.uid == user.uid);
    final color = user.isAdmin ? AppColors.secondaryDark : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: UserAvatar(initial: user.initial, color: color),
          title: Row(
            children: [
              Flexible(
                child: Text(user.name,
                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 6),
              AppBadge(
                label: isMe ? 'أنت' : FormatUtils.role(user.role),
                foreground: color,
                background: color.withValues(alpha: 0.1),
              ),
            ],
          ),
          subtitle: Text(
            '${user.email}\n${user.phone}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
          isThreeLine: true,
          trailing: isMe
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(value: user.isActive, onChanged: (v) => _toggle(context, v)),
                    Text(
                      user.isActive ? 'نشط' : 'موقوف',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: user.isActive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AddStaffSheet extends StatefulWidget {
  const _AddStaffSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AccountActionsCubit>(),
        child: const _AddStaffSheet(),
      ),
    );
  }

  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = UserRole.worker;
  bool _submitted = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _submitted = true;
    context.read<AccountActionsCubit>().createStaff(CreateStaffParams(
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          password: _password.text,
          role: _role,
        ));
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
                const Text('إضافة موظف جديد', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: UserRole.worker, label: Text('عامل'), icon: Icon(Icons.engineering_outlined)),
                    ButtonSegment(
                        value: UserRole.admin,
                        label: Text('مدير'),
                        icon: Icon(Icons.admin_panel_settings_outlined)),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'الاسم *', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => Validators.required(v, 'أدخل الاسم'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف *', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration:
                      const InputDecoration(labelText: 'البريد الإلكتروني *', prefixIcon: Icon(Icons.email_outlined)),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'كلمة مرور مبدئية *',
                    prefixIcon: Icon(Icons.lock_outline),
                    helperText: 'أرسلها للموظف، ويمكنه تغييرها من "نسيت كلمة المرور"',
                  ),
                  validator: Validators.password,
                ),
                if (state is SubmissionFailure) ...[
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'إنشاء الحساب',
                  icon: Icons.person_add_alt_1,
                  isLoading: state is SubmissionLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
