import 'package:flutter/foundation.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../core/errors/app_exceptions.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repo;

  CustomerProvider({CustomerRepository? repo})
      : _repo = repo ?? CustomerRepository();

  List<UserModel> _customers = [];
  String _searchQuery = '';
  bool isLoading = true;
  String? errorMessage;
  String? successMessage;

  List<UserModel> get filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final q = _searchQuery.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();
  }

  // Per-customer payment history (loaded on demand)
  final Map<String, List<PaymentModel>> _paymentCache = {};

  void init() {
    _repo.watchCustomers().listen((list) {
      _customers = list;
      isLoading = false;
      notifyListeners();
    });
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Stream<List<PaymentModel>> watchPayments(String customerId) =>
      _repo.watchPaymentHistory(customerId);

  Stream<UserModel?> watchCustomer(String uid) => _repo.watchCustomer(uid);

  Future<bool> recordPayment({
    required String customerId,
    required double amount,
    required String adminId,
    required String adminName,
    String? notes,
  }) async {
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.recordPayment(
        customerId: customerId,
        amount: amount,
        adminId: adminId,
        adminName: adminName,
        notes: notes,
      );
      successMessage = 'تم تسجيل الدفعة بنجاح ✓';
      notifyListeners();
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }
}
