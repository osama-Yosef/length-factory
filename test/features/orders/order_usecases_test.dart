import 'package:dartz/dartz.dart' show Right, unit;
import 'package:flutter_test/flutter_test.dart';
import 'package:length_factory/core/errors/failures.dart';
import 'package:length_factory/features/orders/domain/entities/order_entity.dart';
import 'package:length_factory/features/orders/domain/repositories/order_repository.dart';
import 'package:length_factory/features/orders/domain/usecases/order_usecases.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockOrderRepository repo;

  setUpAll(() => registerFallbackValue(order()));
  setUp(() => repo = MockOrderRepository());

  group('PlaceOrderUseCase', () {
    test('computes the total and assigns an order number', () async {
      when(() => repo.placeOrder(any())).thenAnswer(
        (inv) async => Right(inv.positionalArguments.first as OrderEntity),
      );
      final useCase = PlaceOrderUseCase(repo, () => 'NUM1');

      final result = await useCase(const PlaceOrderParams(
        customerId: 'u1',
        customerName: 'أحمد',
        customerPhone: '010',
        note: '  ',
        items: [
          OrderItemEntity(productId: 'a', productName: 'A', productImage: '', unitPrice: 10, quantity: 3),
          OrderItemEntity(productId: 'b', productName: 'B', productImage: '', unitPrice: 5, quantity: 2),
        ],
      ));

      final placed = result.getOrElse(() => throw 'failed');
      expect(placed.totalPrice, 40);
      expect(placed.orderNumber, 'NUM1');
      expect(placed.status, 'pending');
      expect(placed.customerNote, isNull);
    });

    test('rejects an empty cart without calling the repository', () async {
      final result = await PlaceOrderUseCase(repo, () => 'x')(const PlaceOrderParams(
        customerId: 'u1',
        customerName: '',
        customerPhone: '',
        items: [],
      ));
      expect(result.isLeft(), isTrue);
      verifyNever(() => repo.placeOrder(any()));
    });
  });

  group('UpdateOrderStatusUseCase', () {
    test('allows valid transitions', () async {
      when(() => repo.updateStatus(any(), any())).thenAnswer((_) async => const Right(unit));
      final r = await UpdateOrderStatusUseCase(repo)(UpdateOrderStatusParams(order(), 'preparing'));
      expect(r, const Right(unit));
    });

    test('blocks invalid transitions (e.g. completed → pending)', () async {
      final r = await UpdateOrderStatusUseCase(repo)(
        UpdateOrderStatusParams(order(status: 'completed'), 'pending'),
      );
      expect(r.fold((f) => f, (_) => null), isA<ValidationFailure>());
      verifyNever(() => repo.updateStatus(any(), any()));
    });
  });

  test('OrderStatusFlow', () {
    expect(OrderStatusFlow.next('pending'), ['preparing', 'cancelled']);
    expect(OrderStatusFlow.canMove('preparing', 'completed'), isTrue);
    expect(OrderStatusFlow.next('cancelled'), isEmpty);
  });
}
