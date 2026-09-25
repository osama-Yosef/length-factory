import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:length_factory/core/routing/app_router.dart';
import 'package:length_factory/core/usecase/usecase.dart';
import 'package:length_factory/features/auth/domain/entities/auth_session.dart';
import 'package:length_factory/features/auth/domain/usecases/auth_usecases.dart';
import 'package:length_factory/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:length_factory/features/auth/presentation/cubit/auth_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockWatchSession extends Mock implements WatchSessionUseCase {}

class MockSignOut extends Mock implements SignOutUseCase {}

void main() {
  late StreamController<AuthSession> sessions;
  late MockWatchSession watch;
  late MockSignOut signOut;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    sessions = StreamController<AuthSession>();
    watch = MockWatchSession();
    signOut = MockSignOut();
    when(() => watch(any())).thenAnswer((_) => sessions.stream);
    when(() => signOut(any())).thenAnswer((_) async => const Right(unit));
  });

  // Not awaited: close() never completes on a stream nobody listens to.
  tearDown(() {
    sessions.close();
  });

  blocTest<AuthCubit, AuthState>(
    'emits authenticated for an active profile, then unauthenticated on sign-out',
    build: () => AuthCubit(watch, signOut),
    act: (_) async {
      sessions.add(ActiveSession(user()));
      await pumpEventQueue();
      sessions.add(const SignedOutSession());
    },
    expect: () => [
      AuthState.authenticated(user()),
      const AuthState.unauthenticated(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'a deactivated account is signed out with a message',
    build: () => AuthCubit(watch, signOut),
    act: (_) => sessions.add(ActiveSession(user(isActive: false))),
    expect: () => [isA<AuthState>().having((s) => s.message, 'message', isNotNull)],
    verify: (_) => verify(() => signOut(any())).called(1),
  );

  blocTest<AuthCubit, AuthState>(
    'pending profile keeps the app on the splash (unknown)',
    build: () => AuthCubit(watch, signOut),
    seed: () => const AuthState.unauthenticated(),
    act: (_) => sessions.add(const ProfilePendingSession('u1')),
    expect: () => [const AuthState.unknown()],
  );

  group('AppRouter.redirectFor', () {
    test('unknown → splash', () {
      expect(AppRouter.redirectFor(const AuthState.unknown(), '/login'), AppRoutes.splash);
      expect(AppRouter.redirectFor(const AuthState.unknown(), '/'), isNull);
    });

    test('unauthenticated → login, but register is allowed', () {
      expect(AppRouter.redirectFor(const AuthState.unauthenticated(), '/admin'), AppRoutes.login);
      expect(AppRouter.redirectFor(const AuthState.unauthenticated(), '/register'), isNull);
    });

    test('each role is bounced to its own home', () {
      expect(AppRouter.redirectFor(AuthState.authenticated(user(role: 'admin')), '/customer'),
          AppRoutes.adminHome);
      expect(AppRouter.redirectFor(AuthState.authenticated(user(role: 'worker')), '/login'),
          AppRoutes.workerHome);
      expect(AppRouter.redirectFor(AuthState.authenticated(user()), '/customer'), isNull);
    });
  });
}
