import 'package:core/core.dart';
import 'package:dio/dio.dart';

/// Injects the bearer token on every outgoing request and, on a 401,
/// expires the session via [TokenService] so the router's redirect hook can
/// send the user back to sign-in. Token refresh is left to the `auth`
/// feature package to wire in (via [onUnauthorized]), since refreshing
/// requires the auth repository/usecase.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.onUnauthorized});

  /// Called on a 401 response; return `true` if the request was retried
  /// successfully (e.g. after a token refresh) and should not propagate.
  final Future<bool> Function(RequestOptions options)? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = TokenService.instance.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final retried = await onUnauthorized?.call(err.requestOptions) ?? false;
      if (!retried) {
        TokenService.instance.expireSession();
      }
    }
    handler.next(err);
  }
}
