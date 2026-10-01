/// Generic envelope for a successful API call, produced by [ApiClient].
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
    this.meta,
  });

  final bool success;
  final int statusCode;
  final T? data;
  final String? message;
  final Map<String, dynamic>? meta;
}

/// Envelope for a paginated list endpoint.
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;
}
