import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:networking/networking.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_auth_usecase.dart';
import '../states/auth_state.dart';

/// DI chain: apiClient -> remoteDataSource -> repository -> usecase ->
/// controller. Composed via `ref.watch()` — no service locator.
final authApiClientProvider = Provider<ApiClient>((ref) => const ApiClient());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(authApiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

final getAuthUseCaseProvider = Provider<GetAuthUseCase>(
  (ref) => GetAuthUseCase(ref.watch(authRepositoryProvider)),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> load() async {
    state = const AuthState.loading();
    try {
      final items = await ref.read(getAuthUseCaseProvider).call();
      state = AuthState.success(items);
    } catch (e) {
      state = AuthState.failure(e.toString());
    }
  }
}
