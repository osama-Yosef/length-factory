import 'package:flutter/foundation.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repo;

  OrderProvider({OrderRepository? repo}) : _repo = repo ?? OrderRepository();

  List<OrderModel> _orders = [];
  String _statusFilter = 'all';
  String _searchQuery = '';
  bool isLoading = true;
  String? errorMessage;

  List<OrderModel> get filteredOrders {
    var list = _orders;
    if (_statusFilter != 'all') {
      list = list.where((o) => o.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((o) =>
              o.customerName.toLowerCase().contains(q) ||
              o.orderNumber.toLowerCase().contains(q) ||
              o.customerPhone.contains(q))
          .toList();
    }
    return list;
  }

  String get statusFilter => _statusFilter;

  void init() {
    _repo.watchAllOrders().listen((list) {
      _orders = list;
      isLoading = false;
      notifyListeners();
    });
  }

  void setFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> updateStatus(String orderId, String status) async {
    try {
      await _repo.updateStatus(orderId, status);
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      await _repo.updatePaymentStatus(orderId, paymentStatus);
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _repo.deleteOrder(orderId);
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }
}
