import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import '../../features/accounts/data/datasources/accounts_remote_data_source.dart';
import '../../features/accounts/data/repositories/accounts_repository_impl.dart';
import '../../features/accounts/domain/repositories/accounts_repository.dart';
import '../../features/accounts/domain/usecases/accounts_usecases.dart';
import '../../features/accounts/presentation/cubit/account_actions_cubit.dart';
import '../../features/accounts/presentation/cubit/payments_cubit.dart';
import '../../features/accounts/presentation/cubit/users_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_form_cubit.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/dashboard/domain/usecases/watch_dashboard_stats.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/orders/data/datasources/order_remote_data_source.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/data/services/invoice_pdf_service.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders/domain/usecases/order_usecases.dart';
import '../../features/orders/presentation/cubit/checkout_cubit.dart';
import '../../features/orders/presentation/cubit/order_actions_cubit.dart';
import '../../features/orders/presentation/cubit/orders_cubit.dart';
import '../../features/products/data/datasources/product_remote_data_source.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/product_usecases.dart';
import '../../features/products/presentation/cubit/product_actions_cubit.dart';
import '../../features/products/presentation/cubit/products_cubit.dart';
import '../network/dio_client.dart';
import '../services/image_upload_service.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Registers every dependency: External → Data → Domain → Presentation.
///
/// Singletons: stateless services/repositories and app-wide Cubits
/// (session + cart). Factories: screen-scoped Cubits (a fresh instance
/// per screen, closed automatically by `BlocProvider`).
Future<void> initDependencies() async {
  // ───────────── External ─────────────
  sl
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<Dio>(DioClient.create)
    ..registerLazySingleton<Uuid>(() => const Uuid());

  // ───────────── Core services ─────────────
  sl
    ..registerLazySingleton<ImageUploadService>(() => CloudinaryImageUploadService(sl()))
    ..registerLazySingleton<InvoicePdfService>(InvoicePdfService.new);

  // ───────────── Data sources ─────────────
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl(), sl()))
    ..registerLazySingleton<ProductRemoteDataSource>(() => ProductRemoteDataSourceImpl(sl(), sl()))
    ..registerLazySingleton<OrderRemoteDataSource>(() => OrderRemoteDataSourceImpl(sl()))
    ..registerLazySingleton<AccountsRemoteDataSource>(
        () => AccountsRemoteDataSourceImpl(sl(), firebaseSecondaryAuth));

  // ───────────── Repositories ─────────────
  sl
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()))
    ..registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(sl()))
    ..registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl()))
    ..registerLazySingleton<AccountsRepository>(() => AccountsRepositoryImpl(sl()));

  // ───────────── Use cases ─────────────
  sl
    // auth
    ..registerLazySingleton(() => WatchSessionUseCase(sl()))
    ..registerLazySingleton(() => SignInUseCase(sl()))
    ..registerLazySingleton(() => RegisterCustomerUseCase(sl()))
    ..registerLazySingleton(() => SendPasswordResetUseCase(sl()))
    ..registerLazySingleton(() => SignOutUseCase(sl()))
    // products
    ..registerLazySingleton(() => WatchProductsUseCase(sl()))
    ..registerLazySingleton(() => AddProductUseCase(sl()))
    ..registerLazySingleton(() => UpdateProductUseCase(sl()))
    ..registerLazySingleton(() => SetProductActiveUseCase(sl()))
    // orders
    ..registerLazySingleton(() => WatchOrdersUseCase(sl()))
    ..registerLazySingleton(
        () => PlaceOrderUseCase(sl(), () => sl<Uuid>().v4().substring(0, 8).toUpperCase()))
    ..registerLazySingleton(() => UpdateOrderStatusUseCase(sl()))
    ..registerLazySingleton(() => UpdatePaymentStatusUseCase(sl()))
    ..registerLazySingleton(() => SetWorkerNoteUseCase(sl()))
    ..registerLazySingleton(() => DeleteOrderUseCase(sl()))
    // accounts
    ..registerLazySingleton(() => WatchCustomersUseCase(sl()))
    ..registerLazySingleton(() => WatchStaffUseCase(sl()))
    ..registerLazySingleton(() => WatchPaymentsUseCase(sl()))
    ..registerLazySingleton(() => RecordPaymentUseCase(sl()))
    ..registerLazySingleton(() => SetUserActiveUseCase(sl()))
    ..registerLazySingleton(() => CreateStaffAccountUseCase(sl()))
    ..registerLazySingleton(() => UpdateProfileUseCase(sl()))
    // dashboard
    ..registerLazySingleton(() => WatchDashboardStatsUseCase(sl(), sl(), sl()));

  // ───────────── Cubits ─────────────
  sl
    // app-wide
    ..registerLazySingleton(() => AuthCubit(sl(), sl()))
    ..registerLazySingleton(CartCubit.new)
    // screen-scoped
    ..registerFactory(() => AuthFormCubit(sl(), sl(), sl()))
    ..registerFactory(() => ProductsCubit(sl()))
    ..registerFactory(() => ProductActionsCubit(sl(), sl(), sl()))
    ..registerFactory(() => OrdersCubit(sl()))
    ..registerFactory(() => OrderActionsCubit(sl(), sl(), sl(), sl()))
    ..registerFactory(() => CheckoutCubit(sl()))
    ..registerFactory(() => UsersCubit(sl(), sl()))
    ..registerFactory(() => PaymentsCubit(sl()))
    ..registerFactory(() => AccountActionsCubit(sl(), sl(), sl(), sl()))
    ..registerFactory(() => DashboardCubit(sl()));
}
