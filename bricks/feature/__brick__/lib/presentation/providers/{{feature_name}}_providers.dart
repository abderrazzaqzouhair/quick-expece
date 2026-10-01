import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:networking/networking.dart';

import '../../data/datasources/{{feature_name}}_remote_datasource.dart';
import '../../data/repositories/{{feature_name}}_repository_impl.dart';
import '../../domain/repositories/{{feature_name}}_repository.dart';
import '../../domain/usecases/get_{{feature_name}}_usecase.dart';
import '../states/{{feature_name}}_state.dart';

/// DI chain: apiClient -> remoteDataSource -> repository -> usecase ->
/// controller. Composed via `ref.watch()` — no service locator.
final {{#camelCase}}{{feature_name}}{{/camelCase}}ApiClientProvider = Provider<ApiClient>((ref) => const ApiClient());

final {{#camelCase}}{{feature_name}}{{/camelCase}}RemoteDataSourceProvider = Provider<{{#pascalCase}}{{feature_name}}{{/pascalCase}}RemoteDataSource>(
  (ref) => {{#pascalCase}}{{feature_name}}{{/pascalCase}}RemoteDataSource(ref.watch({{#camelCase}}{{feature_name}}{{/camelCase}}ApiClientProvider)),
);

final {{#camelCase}}{{feature_name}}{{/camelCase}}RepositoryProvider = Provider<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository>(
  (ref) => {{#pascalCase}}{{feature_name}}{{/pascalCase}}RepositoryImpl(ref.watch({{#camelCase}}{{feature_name}}{{/camelCase}}RemoteDataSourceProvider)),
);

final get{{#pascalCase}}{{feature_name}}{{/pascalCase}}UseCaseProvider = Provider<Get{{#pascalCase}}{{feature_name}}{{/pascalCase}}UseCase>(
  (ref) => Get{{#pascalCase}}{{feature_name}}{{/pascalCase}}UseCase(ref.watch({{#camelCase}}{{feature_name}}{{/camelCase}}RepositoryProvider)),
);

final {{#camelCase}}{{feature_name}}{{/camelCase}}ControllerProvider =
    NotifierProvider<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Controller, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State>({{#pascalCase}}{{feature_name}}{{/pascalCase}}Controller.new);

class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Controller extends Notifier<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> {
  @override
  {{#pascalCase}}{{feature_name}}{{/pascalCase}}State build() => const {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.initial();

  Future<void> load() async {
    state = const {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.loading();
    try {
      final items = await ref.read(get{{#pascalCase}}{{feature_name}}{{/pascalCase}}UseCaseProvider).call();
      state = {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.success(items);
    } catch (e) {
      state = {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.failure(e.toString());
    }
  }
}
