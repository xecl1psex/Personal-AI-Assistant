import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around [flutter_secure_storage] for secrets
/// (API keys, tokens). Never store secrets in SharedPreferences.
class SecureStorage {
  SecureStorage._();

  static final SecureStorage instance = SecureStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Write [value] under [key]. Passing null deletes the entry.
  Future<void> write(String key, String? value) async {
    // TODO: реализация — учесть исключение PlatformException на эмуляторах.
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  /// Read a secret by [key] (null if absent).
  Future<String?> read(String key) async {
    // TODO: реализация.
    return _storage.read(key: key);
  }

  /// Delete a single secret.
  Future<void> delete(String key) async {
    // TODO: реализация.
    await _storage.delete(key: key);
  }

  /// Wipe all stored secrets (used by "Delete all data" in Settings).
  Future<void> deleteAll() async {
    // TODO: реализация.
    await _storage.deleteAll();
  }
}
