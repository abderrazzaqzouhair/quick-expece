import 'package:networking/networking.dart';

import '../models/expenses_response.dart';

/// Talks to [ApiClient] / [ApiEndpoints], returns raw DTOs. Never returns a
/// domain entity and never catches [ApiException] — that's `RepositoryImpl`'s
/// job.
class ExpensesRemoteDataSource {
  const ExpensesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  // TODO: point this at the real path in ApiEndpoints once one exists for
  // this feature (see packages/networking/lib/endpoints/api_endpoints.dart).
  static const _path = '/expenses';

  Future<List<ExpensesResponse>> getAll() async {
    final response = await _apiClient.get<List<dynamic>>(
      _path,
      decoder: (data) => data as List<dynamic>,
    );
    return (response.data ?? [])
        .map((json) => ExpensesResponse.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
