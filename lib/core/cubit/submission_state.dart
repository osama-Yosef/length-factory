import 'package:equatable/equatable.dart';

/// Generic one-shot action state (form submit, delete, update ...).
///
/// Reused by every "action" Cubit so the UI can react uniformly:
/// show a spinner while [SubmissionLoading], a snack on success/failure.
sealed class SubmissionState extends Equatable {
  const SubmissionState();

  @override
  List<Object?> get props => [];
}

class SubmissionInitial extends SubmissionState {
  const SubmissionInitial();
}

class SubmissionLoading extends SubmissionState {
  const SubmissionLoading();
}

class SubmissionSuccess extends SubmissionState {
  final String? message;

  /// Makes two consecutive identical successes distinct for BlocListener.
  final int stamp;

  SubmissionSuccess([this.message]) : stamp = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [message, stamp];
}

class SubmissionFailure extends SubmissionState {
  final String message;
  final int stamp;

  SubmissionFailure(this.message) : stamp = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [message, stamp];
}
