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
  static const List<String> staff = [admin, worker];
}

/// Order lifecycle status.
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

/// Cloudinary unsigned-upload configuration (used by the Dio client).
///
/// Create an *unsigned* upload preset named [uploadPreset] from the
/// Cloudinary console (Settings → Upload) and put your cloud name here.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = 'YOUR_CLOUD_NAME';
  static const String uploadPreset = 'length_factory';
  static const String rootFolder = 'length_factory';
  static const String baseUrl = 'https://api.cloudinary.com/v1_1';
}

/// App-level constants (durations, limits).
class AppConstants {
  AppConstants._();

  static const String appName = 'Length Factory';

  // Animation
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);

  // Network
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Validation
  static const int minPasswordLength = 6;
  static const int phoneLength = 11; // Egyptian mobile numbers (e.g. 01XXXXXXXXX)

  // Inventory
  static const int lowStockThreshold = 5;

  /// How long to wait for a freshly-created auth account's Firestore
  /// profile before treating it as missing.
  static const Duration profileLoadTimeout = Duration(seconds: 8);
}
