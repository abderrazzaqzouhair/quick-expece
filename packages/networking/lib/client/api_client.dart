import 'package:dio/dio.dart';

import '../exceptions/api_exception.dart';
import '../models/api_response.dart';
import 'dio_client.dart';

/// Thin wrapper around [DioClient.instance.dio] that returns [ApiResponse]
/// on success and always throws a typed [ApiException] on failure — callers
/// (feature `RemoteDataSource`s) never touch Dio types directly.
class ApiClient {
  const ApiClient();

  Dio get _dio => DioClient.instance.dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? decoder,
  }) =>
      _request(() => _dio.get(path, queryParameters: queryParameters), decoder);

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? decoder,
  }) => _request(() => _dio.post(path, data: data), decoder);

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? decoder,
  }) => _request(() => _dio.put(path, data: data), decoder);

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? decoder,
  }) => _request(() => _dio.patch(path, data: data), decoder);

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? decoder,
  }) => _request(() => _dio.delete(path, data: data), decoder);

  Future<ApiResponse<T>> multipart<T>(
    String path,
    FormData formData, {
    T Function(dynamic data)? decoder,
  }) => _request(() => _dio.post(path, data: formData), decoder);

  Future<ApiResponse<T>> _request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data)? decoder,
  ) async {
    try {
      final response = await call();
      final body = response.data;
      final payload = body is Map && body['data'] != null ? body['data'] : body;
      return ApiResponse<T>(
        success: true,
        statusCode: response.statusCode ?? 200,
        data: decoder != null ? decoder(payload) : payload as T?,
        message: body is Map ? body['message'] as String? : null,
        meta: body is Map ? body['meta'] as Map<String, dynamic>? : null,
      );
    } on DioException catch (err) {
      final mapped = err.error;
      if (mapped is ApiException) throw mapped;
      throw ApiException.unknown(err.message ?? 'Unexpected error.');
    }
  }
}
