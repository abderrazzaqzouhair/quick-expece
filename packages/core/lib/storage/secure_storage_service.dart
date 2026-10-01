import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Singleton wrapper around `flutter_secure_storage` for the handful of
/// sensitive values the app persists across sessions.
class SecureStorageService {
  SecureStorageService._() : _storage = const FlutterSecureStorage();

  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<void> setAccessToken(String value) =>
      _storage.write(key: _accessTokenKey, value: value);

  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);
  Future<void> setRefreshToken(String value) =>
      _storage.write(key: _refreshTokenKey, value: value);

  Future<String?> get userId => _storage.read(key: _userIdKey);
  Future<void> setUserId(String value) =>
      _storage.write(key: _userIdKey, value: value);

  Future<void> clear() => _storage.deleteAll();
}
