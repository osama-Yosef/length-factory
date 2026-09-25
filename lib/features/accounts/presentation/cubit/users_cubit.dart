import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/load_status.dart';
import '../../../../core/cubit/safe_emit.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/accounts_usecases.dart';

export '../../../../core/cubit/load_status.dart';

class UsersState extends Equatable {
  final LoadStatus status;
  final List<UserEntity> users;
  final String query;

  /// Customers only: show just those who owe money.
  final bool onlyWithBalance;
  final String? error;

  const UsersState({
    this.status = LoadStatus.loading,
    this.users = const [],
    this.query = '',
    this.onlyWithBalance = false,
    this.error,
  });

  List<UserEntity> get visible {
    Iterable<UserEntity> list = users;
    if (onlyWithBalance) list = list.where((u) => u.balance > 0);
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.email.toLowerCase().contains(q));
    }
    return list.toList();
  }

  double get totalBalance => users.fold(0, (s, u) => s + (u.balance > 0 ? u.balance : 0));

  UserEntity? byId(String uid) {
    for (final u in users) {
      if (u.uid == uid) return u;
    }
    return null;
  }

  UsersState copyWith({
    LoadStatus? status,
    List<UserEntity>? users,
    String? query,
    bool? onlyWithBalance,
    String? error,
  }) {
    return UsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      query: query ?? this.query,
      onlyWithBalance: onlyWithBalance ?? this.onlyWithBalance,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, users, query, onlyWithBalance, error];
}

/// Real-time customers list or staff list.
class UsersCubit extends Cubit<UsersState> with SafeEmit {
  final WatchCustomersUseCase _watchCustomers;
  final WatchStaffUseCase _watchStaff;
  StreamSubscription<List<UserEntity>>? _sub;
  bool _staff = false;

  UsersCubit(this._watchCustomers, this._watchStaff) : super(const UsersState());

  void watchCustomers() => _listen(_watchCustomers(const NoParams()), staff: false);

  void watchStaff() => _listen(_watchStaff(const NoParams()), staff: true);

  void _listen(Stream<List<UserEntity>> stream, {required bool staff}) {
    _staff = staff;
    _sub?.cancel();
    safeEmit(state.copyWith(status: LoadStatus.loading));
    _sub = stream.listen(
      (list) => safeEmit(state.copyWith(status: LoadStatus.loaded, users: list)),
      onError: (Object e) => safeEmit(state.copyWith(status: LoadStatus.error, error: e.toString())),
    );
  }

  void retry() => _staff ? watchStaff() : watchCustomers();

  void search(String q) => safeEmit(state.copyWith(query: q));

  void toggleOnlyWithBalance(bool value) => safeEmit(state.copyWith(onlyWithBalance: value));

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
