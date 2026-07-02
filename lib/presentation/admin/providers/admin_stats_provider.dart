import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';

/// Holds all real-time dashboard KPIs for the Admin home screen.
/// Uses direct Firestore aggregation queries where possible for efficiency.
class AdminStatsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  AdminStatsProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _listenToStats();
  }

  // KPIs
  int totalProducts = 0;
  int totalCustomers = 0;
  int totalOrders = 0;
  int pendingOrders = 0;
  int preparingOrders = 0;
  int completedOrders = 0;
  double totalOutstanding = 0; // sum of all customer balances

  bool isLoading = true;
  String? error;

  final List<void Function()> _cancelListeners = [];

  void _listenToStats() {
    // Products count
    _cancelListeners.add(
      _firestore
          .collection(FirestoreCollections.products)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .listen((s) {
        totalProducts = s.docs.length;
        _notify();
      }).cancel,
    );

    // Customers count + outstanding balance sum
    _cancelListeners.add(
      _firestore
          .collection(FirestoreCollections.users)
          .where('role', isEqualTo: 'customer')
          .snapshots()
          .listen((s) {
        totalCustomers = s.docs.length;
        totalOutstanding = s.docs.fold(
          0,
          (sum, d) => sum + ((d.data()['balance'] as num?)?.toDouble() ?? 0),
        );
        _notify();
      }).cancel,
    );

    // Orders breakdown
    _cancelListeners.add(
      _firestore
          .collection(FirestoreCollections.orders)
          .snapshots()
          .listen((s) {
        totalOrders = s.docs.length;
        pendingOrders = s.docs
            .where((d) => d.data()['status'] == OrderStatus.pending)
            .length;
        preparingOrders = s.docs
            .where((d) => d.data()['status'] == OrderStatus.preparing)
            .length;
        completedOrders = s.docs
            .where((d) => d.data()['status'] == OrderStatus.completed)
            .length;
        isLoading = false;
        _notify();
      }).cancel,
    );
  }

  void _notify() {
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final cancel in _cancelListeners) {
      cancel();
    }
    super.dispose();
  }
}
