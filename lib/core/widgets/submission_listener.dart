import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/submission_state.dart';
import '../utils/ui_helpers.dart';

/// Shows a snack for every success/failure of an action Cubit [C].
/// Optionally runs [onSuccess] (e.g. to close a sheet).
class SubmissionListener<C extends StateStreamable<SubmissionState>> extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSuccess;
  final bool showSnack;

  const SubmissionListener({
    super.key,
    required this.child,
    this.onSuccess,
    this.showSnack = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<C, SubmissionState>(
      listener: (context, state) {
        if (state is SubmissionFailure) {
          if (showSnack) UiHelpers.showSnack(context, state.message, isError: true);
        } else if (state is SubmissionSuccess) {
          if (showSnack && state.message != null) UiHelpers.showSnack(context, state.message!);
          onSuccess?.call();
        }
      },
      child: child,
    );
  }
}
