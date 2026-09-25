import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/load_status.dart';
import '../../../../core/cubit/safe_emit.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/usecases/watch_dashboard_stats.dart';

export '../../../../core/cubit/load_status.dart';

class DashboardState extends Equatable {
  final LoadStatus status;
  final DashboardStats? stats;
  final String? error;

  const DashboardState({this.status = LoadStatus.loading, this.stats, this.error});

  @override
  List<Object?> get props => [status, stats, error];
}

class DashboardCubit extends Cubit<DashboardState> with SafeEmit {
  final WatchDashboardStatsUseCase _watchStats;
  StreamSubscription<DashboardStats>? _sub;

  DashboardCubit(this._watchStats) : super(const DashboardState());

  void watch() {
    _sub?.cancel();
    safeEmit(DashboardState(stats: state.stats));
    _sub = _watchStats(const NoParams()).listen(
      (stats) => safeEmit(DashboardState(status: LoadStatus.loaded, stats: stats)),
      onError: (Object e) =>
          safeEmit(DashboardState(status: LoadStatus.error, stats: state.stats, error: e.toString())),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
