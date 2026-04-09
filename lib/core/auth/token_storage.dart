import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps [FlutterSecureStorage] for JWT persistence.
///
/// On Flutter Web, flutter_secure_storage uses localStorage under the hood
/// (AES-encrypted). The same API works across web, Windows, and mobile.
class TokenStorage {
  static const _accessTokenKey = 'launchpad_access_token';

  static const _storage = FlutterSecureStorage(
    // Web-specific options: encrypt the value in localStorage
    webOptions: WebOptions(dbName: 'launchpad_secure', publicKey: 'launchpad_key'),
  );

  /// Persist [token] to secure storage.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Returns the stored JWT, or `null` if none is saved.
  Future<String?> getToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// Removes the stored JWT (called on logout).
  Future<void> clearToken() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
