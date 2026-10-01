import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:networking/networking.dart';

import '../../data/datasources/categories_remote_datasource.dart';
import '../../data/repositories/categories_repository_impl.dart';
import '../../domain/repositories/categories_repository.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../states/categories_state.dart';

/// DI chain: apiClient -> remoteDataSource -> repository -> usecase ->
/// controller. Composed via `ref.watch()` — no service locator.
final categoriesApiClientProvider = Provider<ApiClient>(
  (ref) => const ApiClient(),
);

final categoriesRemoteDataSourceProvider = Provider<CategoriesRemoteDataSource>(
  (ref) => CategoriesRemoteDataSource(ref.watch(categoriesApiClientProvider)),
);

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) =>
      CategoriesRepositoryImpl(ref.watch(categoriesRemoteDataSourceProvider)),
);

final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>(
  (ref) => GetCategoriesUseCase(ref.watch(categoriesRepositoryProvider)),
);

final categoriesControllerProvider =
    NotifierProvider<CategoriesController, CategoriesState>(
      CategoriesController.new,
    );

class CategoriesController extends Notifier<CategoriesState> {
  @override
  CategoriesState build() => const CategoriesState.initial();

  Future<void> load() async {
    state = const CategoriesState.loading();
    try {
      final items = await ref.read(getCategoriesUseCaseProvider).call();
      state = CategoriesState.success(items);
    } catch (e) {
      state = CategoriesState.failure(e.toString());
    }
  }
}
