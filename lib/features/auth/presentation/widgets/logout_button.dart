import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/ui_helpers.dart';
import '../cubit/auth_cubit.dart';

/// AppBar action that asks for confirmation then signs out.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded),
      tooltip: 'تسجيل الخروج',
      onPressed: () async {
        final ok = await UiHelpers.confirm(
          context,
          title: 'تسجيل الخروج',
          message: 'هل تريد تسجيل الخروج من الحساب؟',
          confirmLabel: 'خروج',
          icon: Icons.logout_rounded,
        );
        if (ok && context.mounted) context.read<AuthCubit>().signOut();
      },
    );
  }
}
