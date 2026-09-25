import 'package:flutter_bloc/flutter_bloc.dart';

/// Prevents "Cannot emit new states after calling close" when an async
/// call completes after the screen (and its Cubit) was disposed —
/// e.g. the router redirects away right after a successful login.
mixin SafeEmit<S> on Cubit<S> {
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }
}
