import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/safe_emit.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/order_usecases.dart';

sealed class CheckoutState extends Equatable {
  const CheckoutState();
  @override
  List<Object?> get props => [];
}

class CheckoutIdle extends CheckoutState {
  const CheckoutIdle();
}

class CheckoutSubmitting extends CheckoutState {
  const CheckoutSubmitting();
}

class CheckoutSuccess extends CheckoutState {
  final OrderEntity order;

  /// Customer balance before the order (to show the new balance).
  final double previousBalance;
  const CheckoutSuccess(this.order, this.previousBalance);

  double get newBalance => previousBalance + order.totalPrice;

  @override
  List<Object?> get props => [order, previousBalance];
}

class CheckoutFailure extends CheckoutState {
  final String message;
  const CheckoutFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class CheckoutCubit extends Cubit<CheckoutState> with SafeEmit {
  final PlaceOrderUseCase _placeOrder;

  CheckoutCubit(this._placeOrder) : super(const CheckoutIdle());

  Future<void> placeOrder({
    required UserEntity customer,
    required List<CartItem> items,
    String? note,
  }) async {
    if (state is CheckoutSubmitting) return;
    safeEmit(const CheckoutSubmitting());
    final r = await _placeOrder(PlaceOrderParams(
      customerId: customer.uid,
      customerName: customer.name,
      customerPhone: customer.phone,
      note: note,
      items: items
          .map((c) => OrderItemEntity(
                productId: c.product.id,
                productName: c.product.name,
                productImage: c.product.imageUrl,
                unitPrice: c.product.price,
                quantity: c.quantity,
              ))
          .toList(),
    ));
    r.fold(
      (f) => safeEmit(CheckoutFailure(f.message)),
      (order) => safeEmit(CheckoutSuccess(order, customer.balance)),
    );
  }
}
