import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'exceptions.dart';
import 'failures.dart';

/// Converts any exception thrown by the Data layer into a [Failure].
Failure mapExceptionToFailure(Object error) {
  if (error is Failure) return error;
  if (error is AuthException) return AuthFailure(error.message);
  if (error is ServerException) return ServerFailure(error.message);
  if (error is AppException) return DatabaseFailure(error.message);
  if (error is fb.FirebaseAuthException) {
    return AuthFailure(AuthException.fromCode(error.code).message);
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return const DatabaseFailure('ليس لديك صلاحية لتنفيذ هذه العملية');
      case 'unavailable':
        return const DatabaseFailure('الخدمة غير متاحة حاليًا، تحقق من اتصالك بالإنترنت');
      case 'failed-precondition':
        return const DatabaseFailure('يلزم إنشاء فهرس (Index) في Firestore لهذا الاستعلام');
    }
    return DatabaseFailure(error.message ?? 'حدث خطأ في قاعدة البيانات');
  }
  return const UnexpectedFailure();
}

/// Runs [body] and wraps the result in `Right`, or a mapped [Failure]
/// in `Left` — keeps every repository method a one-liner.
Future<Either<Failure, T>> guard<T>(Future<T> Function() body) async {
  try {
    return Right(await body());
  } catch (e) {
    return Left(mapExceptionToFailure(e));
  }
}

/// Maps stream errors to [Failure]s so Cubits can show a friendly message.
Stream<T> guardStream<T>(Stream<T> stream) {
  return stream.handleError(
    (Object e, StackTrace st) => throw mapExceptionToFailure(e),
  );
}
