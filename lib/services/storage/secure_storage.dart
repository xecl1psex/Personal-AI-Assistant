import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around [flutter_secure_storage] for secrets
/// (API keys, tokens). Never store secrets in SharedPreferences.
///
/// API keys are stored under the key pattern `api_key_<providerId>`.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  /// Prefix used for every per-provider API key entry.
  static const String apiKeyPrefix = 'api_key_';

  /// Builds the secure-storage key for [providerId]: 'api_key_$providerId'.
  static String _apiKeyKey(String providerId) => '$apiKeyPrefix$providerId';

  /// Save an AI provider API key. Empty [key] deletes the entry instead.
  Future<void> saveApiKey(String providerId, String key) async {
    if (key.isEmpty) {
      await _storage.delete(key: _apiKeyKey(providerId));
    } else {
      await _storage.write(key: _apiKeyKey(providerId), value: key);
    }
  }

  /// Read an AI provider API key (null if not configured).
  Future<String?> getApiKey(String providerId) async {
    return _storage.read(key: _apiKeyKey(providerId));
  }

  /// Delete an AI provider API key.
  Future<void> deleteApiKey(String providerId) async {
    await _storage.delete(key: _apiKeyKey(providerId));
  }

  // ---------------------------------------------------------------------------
  // Generic low-level helpers (kept for backwards compatibility).
  // ---------------------------------------------------------------------------

  /// Write [value] under arbitrary [key]. Passing null deletes the entry.
  Future<void> write(String key, String? value) async {
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  /// Read a secret by [key] (null if absent).
  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  /// Delete a single secret.
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Wipe all stored secrets (used by "Delete all data" in Settings).
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
