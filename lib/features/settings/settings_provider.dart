import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/ai/ai_service.dart';
import '../../services/storage/secure_storage.dart';
import '../../shared/models/provider_config.dart';

/// Application state for AI providers: list of configured providers,
/// the active one, and their API keys.
///
/// * Provider list + active id are persisted in SharedPreferences
///   (`providers` as a JSON string, `active_provider_id`).
/// * API keys live only in secure storage via [SecureStorageService]
///   under `api_key_<providerId>`.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    SecureStorageService? storage,
    AiService? aiService,
  })  : _storage = storage ?? SecureStorageService(),
        _aiService = aiService ?? const AiService();

  static const String prefsKeyProviders = 'providers';
  static const String prefsKeyActiveProviderId = 'active_provider_id';

  final SecureStorageService _storage;
  final AiService _aiService;

  List<ProviderConfig> _providers = <ProviderConfig>[];
  String? _activeProviderId;
  bool _loaded = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// All configured providers (chronological order of adding).
  List<ProviderConfig> get providers =>
      List<ProviderConfig>.unmodifiable(_providers);

  /// Id of the currently active provider (null if none selected).
  String? get activeProviderId => _activeProviderId;

  /// The active [ProviderConfig], or null.
  ProviderConfig? get activeProvider {
    if (_activeProviderId == null) return null;
    for (final ProviderConfig p in _providers) {
      if (p.id == _activeProviderId) return p;
    }
    return null;
  }

  /// True when at least one provider is configured and one is active.
  bool get hasActiveProvider => activeProvider != null;

  /// True after [load] has completed.
  bool get loaded => _loaded;

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Restore providers + active id from SharedPreferences.
  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _providers =
          ProviderConfig.decodeList(prefs.getString(prefsKeyProviders));
      _activeProviderId = prefs.getString(prefsKeyActiveProviderId);
      // Validate the stored active id still exists.
      if (_activeProviderId != null && activeProvider == null) {
        _activeProviderId = _providers.isNotEmpty ? _providers.first.id : null;
      }
    } catch (e, s) {
      debugPrint('SettingsProvider.load failed: $e\n$s');
      _providers = <ProviderConfig>[];
      _activeProviderId = null;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveProviders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      prefsKeyProviders,
      ProviderConfig.encodeList(_providers),
    );
    if (_activeProviderId == null) {
      await prefs.remove(prefsKeyActiveProviderId);
    } else {
      await prefs.setString(prefsKeyActiveProviderId, _activeProviderId!);
    }
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Add a new provider, store its API key securely, persist the list.
  /// The first added provider automatically becomes active.
  ///
  /// The API key is written to secure storage BEFORE the provider list is
  /// persisted, and both writes are fully awaited — so a saved provider can
  /// never exist in SharedPreferences without its key being committed.
  Future<void> addProvider(ProviderConfig config, String apiKey) async {
    // 1. Save the key first (awaited — guarantees the write completed).
    await _storage.saveApiKey(config.id, apiKey);

    // 2. Only then update the in-memory list and persist it.
    _providers = List<ProviderConfig>.from(_providers)..add(config);
    if (_activeProviderId == null) {
      _activeProviderId = config.id;
    }
    await _saveProviders();
    notifyListeners();
  }

  /// Remove a provider and wipe its API key from secure storage.
  Future<void> removeProvider(String id) async {
    _providers = _providers
        .where((ProviderConfig p) => p.id != id)
        .toList(growable: false);
    if (_activeProviderId == id) {
      _activeProviderId = _providers.isNotEmpty ? _providers.first.id : null;
    }
    await _storage.deleteApiKey(id);
    await _saveProviders();
    notifyListeners();
  }

  /// Update an existing provider (matched by [ProviderConfig.id]).
  ///
  /// Replaces the stored config fields and persists the list. The API key is
  /// only touched when [newApiKey] is non-null AND non-empty; passing null or
  /// an empty string preserves the currently stored key (it is never
  /// accidentally wiped by an edit that didn't change it).
  Future<void> updateProvider(
    ProviderConfig config, {
    String? newApiKey,
  }) async {
    final int index =
        _providers.indexWhere((ProviderConfig p) => p.id == config.id);
    if (index == -1) return; // unknown id — ignore

    // Save the new key BEFORE persisting the list (fully awaited).
    if (newApiKey != null && newApiKey.isNotEmpty) {
      await _storage.saveApiKey(config.id, newApiKey);
    }

    _providers = List<ProviderConfig>.from(_providers)..[index] = config;
    await _saveProviders();
    notifyListeners();
  }

  /// Mark [id] as the active provider (null clears selection).
  Future<void> setActiveProvider(String? id) async {
    if (id != null && !_providers.any((ProviderConfig p) => p.id == id)) {
      return; // unknown id — ignore
    }
    _activeProviderId = id;
    await _saveProviders();
    notifyListeners();
  }

  /// Update / replace the API key of an existing provider.
  Future<void> saveApiKey(String providerId, String apiKey) async {
    await _storage.saveApiKey(providerId, apiKey);
  }

  /// Read the API key of a provider (null if not configured).
  Future<String?> getApiKey(String providerId) async {
    return _storage.getApiKey(providerId);
  }

  /// True when the provider with [providerId] has a non-empty API key
  /// stored in secure storage. Local providers (e.g. Ollama) may legally
  /// have no key — treat that via [ModelPreset.isLocal] on the UI side.
  Future<bool> hasApiKey(String providerId) async {
    final String? key = await _storage.getApiKey(providerId);
    return key != null && key.isNotEmpty;
  }

  /// Run a connectivity test against the provider with [providerId].
  /// Returns false if the provider or its API key is missing.
  Future<bool> testConnection(String providerId) async {
    ProviderConfig? config;
    for (final ProviderConfig p in _providers) {
      if (p.id == providerId) {
        config = p;
        break;
      }
    }
    if (config == null) return false;

    final String? apiKey = await _storage.getApiKey(providerId);
    if (apiKey == null || apiKey.isEmpty) return false;

    return _aiService.testConnection(config, apiKey);
  }
}
