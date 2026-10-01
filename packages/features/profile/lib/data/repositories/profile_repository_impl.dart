import 'package:core/core.dart';
import 'package:networking/networking.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../mappers/profile_mappers.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<List<ProfileEntity>> getAll() async {
    try {
      final responses = await _remoteDataSource.getAll();
      return responses.map((r) => r.toEntity()).toList();
    } on ApiException catch (e) {
      throw _toFailure(e);
    }
  }

  Failure _toFailure(ApiException e) => switch (e.kind) {
    ApiExceptionKind.network => NetworkFailure(e.message),
    ApiExceptionKind.timeout => NetworkFailure(e.message),
    ApiExceptionKind.unauthorized => UnauthorizedFailure(e.message),
    ApiExceptionKind.validation => ValidationFailure(
      e.message,
      errors: e.errors,
    ),
    ApiExceptionKind.forbidden ||
    ApiExceptionKind.notFound ||
    ApiExceptionKind.server => ServerFailure(e.message),
    ApiExceptionKind.cancelled ||
    ApiExceptionKind.unknown => UnknownFailure(e.message),
  };
}
