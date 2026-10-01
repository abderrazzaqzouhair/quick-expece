import 'package:networking/networking.dart';

import '../models/{{feature_name}}_response.dart';

/// Talks to [ApiClient] / [ApiEndpoints], returns raw DTOs. Never returns a
/// domain entity and never catches [ApiException] — that's `RepositoryImpl`'s
/// job.
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}RemoteDataSource {
  const {{#pascalCase}}{{feature_name}}{{/pascalCase}}RemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  // TODO: point this at the real path in ApiEndpoints once one exists for
  // this feature (see packages/networking/lib/endpoints/api_endpoints.dart).
  static const _path = '/{{feature_name}}';

  Future<List<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Response>> getAll() async {
    final response = await _apiClient.get<List<dynamic>>(
      _path,
      decoder: (data) => data as List<dynamic>,
    );
    return (response.data ?? [])
        .map((json) => {{#pascalCase}}{{feature_name}}{{/pascalCase}}Response.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
