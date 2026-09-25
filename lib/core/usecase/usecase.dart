import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// A single business action. Returns `Either<Failure, T>`.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// A real-time query. Errors surface as [Failure]s on the stream.
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
