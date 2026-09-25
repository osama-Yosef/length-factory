import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/cubit/submission_state.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../cubit/auth_form_cubit.dart';
import '../widgets/auth_header.dart';

/// Self-serve registration — Customer role only.
/// Admin & Worker accounts are created by an Admin from the Staff tab.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthFormCubit>(),
      child: const RegisterView(),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _emailCtrl, _passwordCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthFormCubit>().register(RegisterParams(
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthFormCubit, SubmissionState>(
      listener: (context, state) {
        if (state is SubmissionFailure) {
          UiHelpers.showSnack(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء حساب جديد')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(subtitle: 'حساب عميل جديد'),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'الاسم بالكامل',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => Validators.required(v, 'أدخل الاسم'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          hintText: '01XXXXXXXXX',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        textDirection: TextDirection.ltr,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscure,
                        textDirection: TextDirection.ltr,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                        validator: (v) =>
                            v != _passwordCtrl.text ? 'كلمتا المرور غير متطابقتين' : null,
                      ),
                      const SizedBox(height: 28),
                      BlocBuilder<AuthFormCubit, SubmissionState>(
                        builder: (context, state) => PrimaryButton(
                          label: 'إنشاء الحساب',
                          icon: Icons.person_add_alt_1_rounded,
                          isLoading: state is SubmissionLoading,
                          onPressed: _submit,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.canPop() ? context.pop() : null,
                        child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
