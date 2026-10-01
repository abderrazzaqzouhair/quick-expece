import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../endpoints/api_endpoints.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/error_interceptor.dart';

/// Singleton Dio instance. Call [DioClient.instance.init] once at app
/// startup, before `runApp`.
class DioClient {
  DioClient._();

  static final DioClient instance = DioClient._();

  late final Dio dio;
  bool _initialized = false;

  void init({
    Future<bool> Function(RequestOptions options)? onUnauthorized,
    bool enableLogging = true,
  }) {
    if (_initialized) return;
    _initialized = true;

    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(onUnauthorized: onUnauthorized),
      ErrorInterceptor(),
      if (enableLogging)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: true,
        ),
    ]);
  }
}
