import '../../domain/entities/expenses_entity.dart';
import '../models/expenses_response.dart';

/// DTO -> domain entity mapping. Keep all shape-translation here so
/// `RepositoryImpl` stays focused on orchestration.
extension ExpensesResponseMapper on ExpensesResponse {
  ExpensesEntity toEntity() => ExpensesEntity(id: id);
}
