import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import 'worker_queue_screen.dart';

/// Worker Shell — single-screen app (no bottom nav needed).
/// Workers only see the production queue.
class WorkerShell extends StatelessWidget {
  const WorkerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkerQueueScreen();
  }
}
