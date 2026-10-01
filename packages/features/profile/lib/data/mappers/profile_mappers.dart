import '../../domain/entities/profile_entity.dart';
import '../models/profile_response.dart';

/// DTO -> domain entity mapping. Keep all shape-translation here so
/// `RepositoryImpl` stays focused on orchestration.
extension ProfileResponseMapper on ProfileResponse {
  ProfileEntity toEntity() => ProfileEntity(id: id);
}
