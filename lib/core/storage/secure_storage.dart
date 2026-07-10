import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  Future<void> saveCachedUserJson(String userJson) async {
    await _storage.write(key: 'cached_user', value: userJson);
  }

  Future<String?> getCachedUserJson() async {
    return await _storage.read(key: 'cached_user');
  }

  // ─── Google Places API Key ────────────────────────────────────────────────
  static const String _googlePlacesApiKeyKey = 'google_places_api_key';

  Future<void> saveGooglePlacesApiKey(String key) async {
    await _storage.write(key: _googlePlacesApiKeyKey, value: key);
  }

  Future<String?> getGooglePlacesApiKey() async {
    return await _storage.read(key: _googlePlacesApiKeyKey);
  }

  Future<void> deleteGooglePlacesApiKey() async {
    await _storage.delete(key: _googlePlacesApiKeyKey);
  }
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      try {
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _userIdKey);
        await _storage.delete(key: 'cached_user');
      } catch (_) {}
    }
  }
}
