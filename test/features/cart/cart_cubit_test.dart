import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:length_factory/features/cart/presentation/cubit/cart_cubit.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('CartCubit', () {
    test('starts empty', () {
      final cubit = CartCubit();
      expect(cubit.state.isEmpty, isTrue);
      expect(cubit.state.totalPrice, 0);
    });

    blocTest<CartCubit, CartState>(
      'add() adds a product and computes totals',
      build: CartCubit.new,
      act: (c) => c
        ..add(product(price: 50))
        ..add(product(price: 50), quantity: 2),
      verify: (c) {
        expect(c.state.itemCount, 1);
        expect(c.state.totalQuantity, 3);
        expect(c.state.totalPrice, 150);
      },
    );

    blocTest<CartCubit, CartState>(
      'add() never exceeds available stock',
      build: CartCubit.new,
      act: (c) => c.add(product(quantity: 3), quantity: 10),
      verify: (c) => expect(c.state.quantityOf('p1'), 3),
    );

    blocTest<CartCubit, CartState>(
      'add() ignores out-of-stock products',
      build: CartCubit.new,
      act: (c) => c.add(product(quantity: 0)),
      expect: () => <CartState>[],
    );

    blocTest<CartCubit, CartState>(
      'increment stops at stock; decrement at 1 removes the line',
      build: CartCubit.new,
      act: (c) {
        c.add(product(quantity: 2));
        c.increment('p1');
        c.increment('p1'); // capped
        c.decrement('p1');
        c.decrement('p1'); // removes
      },
      verify: (c) => expect(c.state.isEmpty, isTrue),
    );

    blocTest<CartCubit, CartState>(
      'syncWithCatalog refreshes price and drops hidden / out-of-stock products',
      build: CartCubit.new,
      act: (c) {
        c.add(product(id: 'a', price: 10, quantity: 5), quantity: 4);
        c.add(product(id: 'b', price: 10));
        c.add(product(id: 'c', price: 10));
        c.syncWithCatalog([
          product(id: 'a', price: 20, quantity: 2), // price up, stock down
          product(id: 'b', isActive: false),
          product(id: 'c', quantity: 0),
        ]);
      },
      verify: (c) {
        expect(c.state.itemCount, 1);
        expect(c.state.quantityOf('a'), 2);
        expect(c.state.totalPrice, 40);
      },
    );

    blocTest<CartCubit, CartState>(
      'clear empties the cart',
      build: CartCubit.new,
      act: (c) => c
        ..add(product())
        ..clear(),
      verify: (c) => expect(c.state.isEmpty, isTrue),
    );
  });
}
