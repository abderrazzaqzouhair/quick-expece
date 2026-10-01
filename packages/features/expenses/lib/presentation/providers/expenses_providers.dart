import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:networking/networking.dart';

import '../../data/datasources/expenses_remote_datasource.dart';
import '../../data/repositories/expenses_repository_impl.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../states/expenses_state.dart';

/// DI chain: apiClient -> remoteDataSource -> repository -> usecase ->
/// controller. Composed via `ref.watch()` — no service locator.
final expensesApiClientProvider = Provider<ApiClient>(
  (ref) => const ApiClient(),
);

final expensesRemoteDataSourceProvider = Provider<ExpensesRemoteDataSource>(
  (ref) => ExpensesRemoteDataSource(ref.watch(expensesApiClientProvider)),
);

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepositoryImpl(ref.watch(expensesRemoteDataSourceProvider)),
);

final getExpensesUseCaseProvider = Provider<GetExpensesUseCase>(
  (ref) => GetExpensesUseCase(ref.watch(expensesRepositoryProvider)),
);

final expensesControllerProvider =
    NotifierProvider<ExpensesController, ExpensesState>(ExpensesController.new);

class ExpensesController extends Notifier<ExpensesState> {
  @override
  ExpensesState build() => const ExpensesState.initial();

  Future<void> load() async {
    state = const ExpensesState.loading();
    try {
      final items = await ref.read(getExpensesUseCaseProvider).call();
      state = ExpensesState.success(items);
    } catch (e) {
      state = ExpensesState.failure(e.toString());
    }
  }
}
