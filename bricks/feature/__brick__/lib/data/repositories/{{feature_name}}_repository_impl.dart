import 'package:core/core.dart';
import 'package:networking/networking.dart';

import '../../domain/entities/{{feature_name}}_entity.dart';
import '../../domain/repositories/{{feature_name}}_repository.dart';
import '../datasources/{{feature_name}}_remote_datasource.dart';
import '../mappers/{{feature_name}}_mappers.dart';

class {{#pascalCase}}{{feature_name}}{{/pascalCase}}RepositoryImpl implements {{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository {
  const {{#pascalCase}}{{feature_name}}{{/pascalCase}}RepositoryImpl(this._remoteDataSource);

  final {{#pascalCase}}{{feature_name}}{{/pascalCase}}RemoteDataSource _remoteDataSource;

  @override
  Future<List<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Entity>> getAll() async {
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
    ApiExceptionKind.validation => ValidationFailure(e.message, errors: e.errors),
    ApiExceptionKind.forbidden ||
    ApiExceptionKind.notFound ||
    ApiExceptionKind.server => ServerFailure(e.message),
    ApiExceptionKind.cancelled || ApiExceptionKind.unknown => UnknownFailure(e.message),
  };
}
