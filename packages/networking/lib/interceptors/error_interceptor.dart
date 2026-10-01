import 'package:dio/dio.dart';

import '../exceptions/api_exception.dart';

/// Central error logging + translation of raw [DioException]s into a typed
/// [ApiException], attached to `err.error` so [ApiClient] can rethrow it.
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({this.onApiError});

  final void Function(DioException err)? onApiError;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    onApiError?.call(err);
    handler.next(err.copyWith(error: _mapToApiException(err)));
  }

  ApiException _mapToApiException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException.timeout();
      case DioExceptionType.connectionError:
        return ApiException.network();
      case DioExceptionType.cancel:
        return ApiException.cancelled();
      case DioExceptionType.badResponse:
        return _mapStatusCode(err);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException.unknown(err.message ?? 'Unexpected error.');
    }
  }

  ApiException _mapStatusCode(DioException err) {
    final statusCode = err.response?.statusCode ?? 0;
    final data = err.response?.data;
    final message = data is Map && data['message'] is String
        ? data['message'] as String
        : 'Something went wrong.';

    switch (statusCode) {
      case 401:
        return ApiException.unauthorized(message);
      case 403:
        return ApiException.forbidden(message);
      case 404:
        return ApiException.notFound(message);
      case 422:
        final rawErrors = data is Map ? data['errors'] : null;
        final errors = <String, List<String>>{
          if (rawErrors is Map)
            for (final entry in rawErrors.entries)
              entry.key as String: List<String>.from(entry.value as List),
        };
        return ApiException.validation(message, errors: errors);
      default:
        return ApiException.server(message, statusCode: statusCode);
    }
  }
}
