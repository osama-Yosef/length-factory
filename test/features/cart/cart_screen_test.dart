import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:length_factory/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:length_factory/features/cart/presentation/screens/cart_screen.dart';

import '../../helpers/fixtures.dart';

void main() {
  Widget wrap(CartCubit cart) => MaterialApp(
        home: BlocProvider.value(value: cart, child: const CartScreen()),
      );

  testWidgets('shows the empty state', (tester) async {
    await tester.pumpWidget(wrap(CartCubit()));
    expect(find.text('السلة فارغة'), findsOneWidget);
  });

  testWidgets('lists items and updates quantity with +', (tester) async {
    final cart = CartCubit()..add(product(name: 'لوح خشب', price: 50, quantity: 5));
    await tester.pumpWidget(wrap(cart));

    expect(find.text('لوح خشب'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // stepper + pieces count
    expect(find.text('متابعة لتأكيد الطلب'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(cart.state.quantityOf('p1'), 2);
    expect(find.text('2'), findsWidgets);
    expect(find.text('1'), findsNothing);
  });
}
