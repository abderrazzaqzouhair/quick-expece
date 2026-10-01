/// Typed transport-layer error surfaced by [ApiClient]. `RepositoryImpl`
/// classes catch this and map it onto a domain `Failure` — `domain`/
/// `presentation` layers never see `ApiException` directly.
class ApiException implements Exception {
  const ApiException._({
    required this.kind,
    required this.message,
    this.statusCode,
    this.errors = const {},
  });

  factory ApiException.network([String message = 'No internet connection.']) =>
      ApiException._(kind: ApiExceptionKind.network, message: message);

  factory ApiException.timeout([String message = 'Request timed out.']) =>
      ApiException._(kind: ApiExceptionKind.timeout, message: message);

  factory ApiException.unauthorized([String message = 'Session expired.']) =>
      ApiException._(
        kind: ApiExceptionKind.unauthorized,
        message: message,
        statusCode: 401,
      );

  factory ApiException.forbidden([String message = 'Forbidden.']) =>
      ApiException._(
        kind: ApiExceptionKind.forbidden,
        message: message,
        statusCode: 403,
      );

  factory ApiException.notFound([String message = 'Not found.']) =>
      ApiException._(
        kind: ApiExceptionKind.notFound,
        message: message,
        statusCode: 404,
      );

  factory ApiException.validation(
    String message, {
    Map<String, List<String>> errors = const {},
  }) => ApiException._(
    kind: ApiExceptionKind.validation,
    message: message,
    statusCode: 422,
    errors: errors,
  );

  factory ApiException.server(String message, {int statusCode = 500}) =>
      ApiException._(
        kind: ApiExceptionKind.server,
        message: message,
        statusCode: statusCode,
      );

  factory ApiException.cancelled([String message = 'Request cancelled.']) =>
      ApiException._(kind: ApiExceptionKind.cancelled, message: message);

  factory ApiException.unknown([String message = 'Unexpected error.']) =>
      ApiException._(kind: ApiExceptionKind.unknown, message: message);

  final ApiExceptionKind kind;
  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}

enum ApiExceptionKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  cancelled,
  unknown,
}
