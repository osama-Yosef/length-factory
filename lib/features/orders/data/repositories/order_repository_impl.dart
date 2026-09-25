import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remote;

  OrderRepositoryImpl(this._remote);

  @override
  Stream<List<OrderEntity>> watchAllOrders() => guardStream(_remote.watchAllOrders());

  @override
  Stream<List<OrderEntity>> watchCustomerOrders(String customerId) =>
      guardStream(_remote.watchCustomerOrders(customerId));

  @override
  Stream<List<OrderEntity>> watchWorkerQueue() => guardStream(_remote.watchWorkerQueue());

  @override
  Future<Either<Failure, OrderEntity>> placeOrder(OrderEntity order) =>
      guard(() => _remote.placeOrder(OrderModel.fromEntity(order)));

  @override
  Future<Either<Failure, Unit>> updateStatus(String orderId, String newStatus) =>
      guard(() async {
        await _remote.updateStatus(orderId, newStatus);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> updatePaymentStatus(String orderId, String paymentStatus) =>
      guard(() async {
        await _remote.updatePaymentStatus(orderId, paymentStatus);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> setWorkerNote(String orderId, String note) => guard(() async {
        await _remote.setWorkerNote(orderId, note);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteOrder(String orderId) => guard(() async {
        await _remote.deleteOrder(orderId);
        return unit;
      });
}
