/// Centralized constants for the Length Factory application.
///
/// Keeping every "magic string" in one place avoids typos when
/// referencing Firestore field/collection names or enum-like values
/// across the Data, Domain and Presentation layers.
library;

/// Firestore collection names.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String payments = 'payments';
}

/// User roles stored on the `users` document and used for
/// role-based routing + Firestore security rules.
class UserRole {
  UserRole._();

  static const String admin = 'admin';
  static const String customer = 'customer';
  static const String worker = 'worker';

  static const List<String> all = [admin, customer, worker];
}

/// Order lifecycle status.
///
/// NOTE: Order of declaration matters for the Kanban-style admin
/// board and for the worker production queue filtering.
class OrderStatus {
  OrderStatus._();

  static const String pending = 'pending';
  static const String preparing = 'preparing';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> all = [pending, preparing, completed, cancelled];

  /// Statuses that are still "active" and therefore visible
  /// on the Worker production queue.
  static const List<String> activeForWorker = [pending, preparing];
}

/// Payment status of an order (separate from order production status).
class PaymentStatus {
  PaymentStatus._();

  static const String unpaid = 'unpaid';
  static const String partiallyPaid = 'partially_paid';
  static const String paid = 'paid';

  static const List<String> all = [unpaid, partiallyPaid, paid];
}

/// Shared Preferences keys.
class PrefsKeys {
  PrefsKeys._();

  static const String themeMode = 'theme_mode';
  static const String cachedRole = 'cached_role';
  static const String fcmToken = 'fcm_token';
}

/// App-level constants (paddings, durations, limits).
class AppConstants {
  AppConstants._();

  static const String appName = 'Length Factory';

  // Pagination
  static const int productsPageSize = 20;
  static const int ordersPageSize = 25;
  static const int customersPageSize = 25;

  // Animation
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);

  // Validation
  static const int minPasswordLength = 6;
  static const int phoneLength = 11; // Egyptian mobile numbers (e.g. 01XXXXXXXXX)
}
