import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:networking/networking.dart';

import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../states/profile_state.dart';

/// DI chain: apiClient -> remoteDataSource -> repository -> usecase ->
/// controller. Composed via `ref.watch()` — no service locator.
final profileApiClientProvider = Provider<ApiClient>(
  (ref) => const ApiClient(),
);

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSource(ref.watch(profileApiClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider)),
);

final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState.initial();

  Future<void> load() async {
    state = const ProfileState.loading();
    try {
      final items = await ref.read(getProfileUseCaseProvider).call();
      state = ProfileState.success(items);
    } catch (e) {
      state = ProfileState.failure(e.toString());
    }
  }
}
