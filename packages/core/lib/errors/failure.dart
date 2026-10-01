import 'package:equatable/equatable.dart';

/// Domain-level failure surfaced to presentation state (e.g. `AuthState.failure`).
/// Data-layer code maps transport errors (like `ApiException`) onto this type
/// so that `domain`/`presentation` never depend on the networking package.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expired.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.errors = const {}});

  final Map<String, List<String>> errors;

  @override
  List<Object?> get props => [message, errors];
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server.']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unexpected error.']);
}
