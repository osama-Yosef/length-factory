import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/widgets/submission_listener.dart';
import '../../orders/domain/usecases/order_usecases.dart';
import '../../orders/presentation/cubit/order_actions_cubit.dart';
import '../../orders/presentation/cubit/orders_cubit.dart';
import '../../orders/presentation/screens/worker_queue_screen.dart';

/// Worker area — a single production-queue screen.
class WorkerShell extends StatelessWidget {
  const WorkerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<OrdersCubit>()..watch(const WorkerQueueQuery())),
        BlocProvider(create: (_) => sl<OrderActionsCubit>()),
      ],
      child: const SubmissionListener<OrderActionsCubit>(child: WorkerQueueScreen()),
    );
  }
}
