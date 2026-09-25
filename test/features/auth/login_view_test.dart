import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:length_factory/core/cubit/submission_state.dart';
import 'package:length_factory/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:length_factory/features/auth/presentation/cubit/auth_form_cubit.dart';
import 'package:length_factory/features/auth/presentation/cubit/auth_state.dart';
import 'package:length_factory/features/auth/presentation/screens/login_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockAuthFormCubit extends MockCubit<SubmissionState> implements AuthFormCubit {}

void main() {
  late MockAuthCubit auth;
  late MockAuthFormCubit form;

  setUp(() {
    auth = MockAuthCubit();
    form = MockAuthFormCubit();
    when(() => auth.state).thenReturn(const AuthState.unauthenticated());
    when(() => form.state).thenReturn(const SubmissionInitial());
    when(() => form.signIn(any(), any())).thenAnswer((_) async {});
  });

  Widget wrap() => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<AuthFormCubit>.value(value: form),
            ],
            child: const LoginView(),
          ),
        ),
      );

  testWidgets('renders email, password and the login button', (tester) async {
    await tester.pumpWidget(wrap());
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('shows validation errors and does not submit when empty', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pump();

    expect(find.text('أدخل البريد الإلكتروني'), findsOneWidget);
    expect(find.text('أدخل كلمة المرور'), findsOneWidget);
    verifyNever(() => form.signIn(any(), any()));
  });

  testWidgets('submits valid credentials to the cubit', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pump();

    verify(() => form.signIn('a@b.com', '123456')).called(1);
  });

  testWidgets('shows a spinner while loading', (tester) async {
    when(() => form.state).thenReturn(const SubmissionLoading());
    await tester.pumpWidget(wrap());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
