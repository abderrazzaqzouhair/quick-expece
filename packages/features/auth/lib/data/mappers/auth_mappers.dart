import '../../domain/entities/auth_entity.dart';
import '../models/auth_response.dart';

/// DTO -> domain entity mapping. Keep all shape-translation here so
/// `RepositoryImpl` stays focused on orchestration.
extension AuthResponseMapper on AuthResponse {
  AuthEntity toEntity() => AuthEntity(id: id);
}
