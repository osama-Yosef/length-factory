import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/order_entity.dart';

abstract class OrderRepository {
  Stream<List<OrderEntity>> watchAllOrders();
  Stream<List<OrderEntity>> watchCustomerOrders(String customerId);
  Stream<List<OrderEntity>> watchWorkerQueue();

  /// Atomically: creates the order, increases the customer's balance and
  /// decrements stock. Returns the stored order (with id).
  Future<Either<Failure, OrderEntity>> placeOrder(OrderEntity order);

  /// Moving to `cancelled` reverses the balance and restores stock.
  Future<Either<Failure, Unit>> updateStatus(String orderId, String newStatus);

  Future<Either<Failure, Unit>> updatePaymentStatus(String orderId, String paymentStatus);

  Future<Either<Failure, Unit>> setWorkerNote(String orderId, String note);

  /// Deletes the order (reversing balance/stock first if it wasn't cancelled).
  Future<Either<Failure, Unit>> deleteOrder(String orderId);
}
