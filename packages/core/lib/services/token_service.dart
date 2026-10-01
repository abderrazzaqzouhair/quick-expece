import '../storage/secure_storage_service.dart';

/// Coordinates the in-memory access token (read synchronously by
/// `AuthInterceptor` on every request) with the persisted token in secure
/// storage, and notifies listeners when the session expires so the router
/// can redirect to the sign-in screen.
class TokenService {
  TokenService._();

  static final TokenService instance = TokenService._();

  String? _accessToken;
  String? get accessToken => _accessToken;

  /// Invoked by the router's redirect hook / auth-gate after a 401 that the
  /// refresh flow couldn't recover from.
  void Function()? onSessionExpired;

  Future<void> restoreFromStorage() async {
    _accessToken = await SecureStorageService.instance.accessToken;
  }

  Future<void> setSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    _accessToken = accessToken;
    await SecureStorageService.instance.setAccessToken(accessToken);
    await SecureStorageService.instance.setRefreshToken(refreshToken);
    await SecureStorageService.instance.setUserId(userId);
  }

  Future<void> clearSession() async {
    _accessToken = null;
    await SecureStorageService.instance.clear();
  }

  void expireSession() {
    _accessToken = null;
    onSessionExpired?.call();
  }
}
