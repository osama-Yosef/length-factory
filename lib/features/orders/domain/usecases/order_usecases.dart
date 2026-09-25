import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

// ───────────────────────── Queries ─────────────────────────

sealed class OrdersQuery extends Equatable {
  const OrdersQuery();
  @override
  List<Object?> get props => [];
}

class AllOrdersQuery extends OrdersQuery {
  const AllOrdersQuery();
}

class CustomerOrdersQuery extends OrdersQuery {
  final String customerId;
  const CustomerOrdersQuery(this.customerId);
  @override
  List<Object?> get props => [customerId];
}

class WorkerQueueQuery extends OrdersQuery {
  const WorkerQueueQuery();
}

class WatchOrdersUseCase extends StreamUseCase<List<OrderEntity>, OrdersQuery> {
  final OrderRepository _repo;
  WatchOrdersUseCase(this._repo);

  @override
  Stream<List<OrderEntity>> call(OrdersQuery query) => switch (query) {
        AllOrdersQuery() => _repo.watchAllOrders(),
        CustomerOrdersQuery(:final customerId) => _repo.watchCustomerOrders(customerId),
        WorkerQueueQuery() => _repo.watchWorkerQueue(),
      };
}

// ───────────────────────── Place order ─────────────────────────

class PlaceOrderParams extends Equatable {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItemEntity> items;
  final String? note;

  const PlaceOrderParams({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    this.note,
  });

  @override
  List<Object?> get props => [customerId, items, note];
}

class PlaceOrderUseCase extends UseCase<OrderEntity, PlaceOrderParams> {
  final OrderRepository _repo;
  final String Function() _orderNumberGenerator;

  PlaceOrderUseCase(this._repo, this._orderNumberGenerator);

  @override
  Future<Either<Failure, OrderEntity>> call(PlaceOrderParams p) async {
    if (p.items.isEmpty) return const Left(ValidationFailure('السلة فارغة'));
    if (p.items.any((i) => i.quantity <= 0)) {
      return const Left(ValidationFailure('كمية غير صحيحة في أحد المنتجات'));
    }
    final total = p.items.fold<double>(0, (s, i) => s + i.lineTotal);
    final note = p.note?.trim();
    final order = OrderEntity(
      id: '',
      orderNumber: _orderNumberGenerator(),
      customerId: p.customerId,
      customerName: p.customerName,
      customerPhone: p.customerPhone,
      items: p.items,
      totalPrice: total,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
      customerNote: (note == null || note.isEmpty) ? null : note,
      createdAt: DateTime.now(),
    );
    return _repo.placeOrder(order);
  }
}

// ───────────────────────── Mutations ─────────────────────────

class UpdateOrderStatusParams extends Equatable {
  final OrderEntity order;
  final String newStatus;
  const UpdateOrderStatusParams(this.order, this.newStatus);

  @override
  List<Object?> get props => [order.id, newStatus];
}

class UpdateOrderStatusUseCase extends UseCase<Unit, UpdateOrderStatusParams> {
  final OrderRepository _repo;
  UpdateOrderStatusUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(UpdateOrderStatusParams p) async {
    if (!OrderStatusFlow.canMove(p.order.status, p.newStatus)) {
      return const Left(ValidationFailure('لا يمكن تغيير حالة الطلب بهذا الشكل'));
    }
    return _repo.updateStatus(p.order.id, p.newStatus);
  }
}

class UpdatePaymentStatusParams extends Equatable {
  final String orderId;
  final String paymentStatus;
  const UpdatePaymentStatusParams(this.orderId, this.paymentStatus);

  @override
  List<Object?> get props => [orderId, paymentStatus];
}

class UpdatePaymentStatusUseCase extends UseCase<Unit, UpdatePaymentStatusParams> {
  final OrderRepository _repo;
  UpdatePaymentStatusUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(UpdatePaymentStatusParams p) async {
    if (!PaymentStatus.all.contains(p.paymentStatus)) {
      return const Left(ValidationFailure('حالة دفع غير معروفة'));
    }
    return _repo.updatePaymentStatus(p.orderId, p.paymentStatus);
  }
}

class SetWorkerNoteParams extends Equatable {
  final String orderId;
  final String note;
  const SetWorkerNoteParams(this.orderId, this.note);

  @override
  List<Object?> get props => [orderId, note];
}

class SetWorkerNoteUseCase extends UseCase<Unit, SetWorkerNoteParams> {
  final OrderRepository _repo;
  SetWorkerNoteUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(SetWorkerNoteParams p) =>
      _repo.setWorkerNote(p.orderId, p.note.trim());
}

class DeleteOrderUseCase extends UseCase<Unit, String> {
  final OrderRepository _repo;
  DeleteOrderUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(String orderId) => _repo.deleteOrder(orderId);
}
