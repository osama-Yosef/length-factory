import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/load_status.dart';
import '../../../../core/cubit/safe_emit.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/accounts_usecases.dart';

export '../../../../core/cubit/load_status.dart';

class PaymentsState extends Equatable {
  final LoadStatus status;
  final List<PaymentEntity> payments;
  final String? error;

  const PaymentsState({
    this.status = LoadStatus.loading,
    this.payments = const [],
    this.error,
  });

  double get totalPaid => payments.fold(0, (s, p) => s + p.amount);

  @override
  List<Object?> get props => [status, payments, error];
}

/// Real-time payment history for a single customer.
class PaymentsCubit extends Cubit<PaymentsState> with SafeEmit {
  final WatchPaymentsUseCase _watchPayments;
  StreamSubscription<List<PaymentEntity>>? _sub;
  String? _customerId;

  PaymentsCubit(this._watchPayments) : super(const PaymentsState());

  void watch(String customerId) {
    _customerId = customerId;
    _sub?.cancel();
    safeEmit(const PaymentsState());
    _sub = _watchPayments(customerId).listen(
      (list) => safeEmit(PaymentsState(status: LoadStatus.loaded, payments: list)),
      onError: (Object e) => safeEmit(PaymentsState(status: LoadStatus.error, error: e.toString())),
    );
  }

  void retry() {
    if (_customerId != null) watch(_customerId!);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
