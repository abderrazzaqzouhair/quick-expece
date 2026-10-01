import 'package:networking/networking.dart';

import '../models/category_response.dart';

/// Talks to [ApiClient] / [ApiEndpoints], returns raw DTOs. Never returns a
/// domain entity and never catches [ApiException] — that's `RepositoryImpl`'s
/// job.
class CategoriesRemoteDataSource {
  const CategoriesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// The categories the authenticated user has activated. Global categories
  /// not yet activated are available at `ApiEndpoints.categoriesAvailable`
  /// — wire a second usecase for that once a "browse more categories" flow
  /// is needed.
  Future<List<CategoryResponse>> getAll() async {
    final response = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.categories,
      decoder: (data) => data as List<dynamic>,
    );
    return (response.data ?? [])
        .map((json) => CategoryResponse.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
