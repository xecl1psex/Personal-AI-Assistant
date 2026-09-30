import 'dart:convert';

/// Configuration of a single AI provider added by the user in Settings.
///
/// Persisted as a JSON list under the `providers` key in SharedPreferences.
/// The API key itself is NEVER stored here — it lives in secure storage
/// under `api_key_<id>` (see SecureStorageService).
class ProviderConfig {
  const ProviderConfig({
    required this.id,
    required this.presetId,
    required this.displayName,
    required this.baseUrl,
    required this.modelName,
    this.familyId = '',
    this.supportsVision = false,
    this.supportsFunctions = false,
  });

  /// Unique id, e.g. 'provider_${DateTime.now().millisecondsSinceEpoch}'.
  final String id;

  /// Id of the [ModelPreset] this config was created from ('gemini', ...).
  /// Kept for backwards compatibility; new configs use [familyId].
  final String presetId;

  /// Id of the [ProviderFamily] this config belongs to ('gemini', 'openai',
  /// ...). Empty string for legacy configs added before the families refactor.
  final String familyId;

  /// User-visible name of the provider entry.
  final String displayName;

  /// OpenAI-compatible base URL, e.g. 'https://api.openai.com/v1'.
  final String baseUrl;

  /// Model name sent in chat requests, e.g. 'gpt-6-astra'.
  final String modelName;

  /// Whether the model accepts image input.
  final bool supportsVision;

  /// Whether the model supports function / tool calling.
  final bool supportsFunctions;

  ProviderConfig copyWith({
    String? id,
    String? presetId,
    String? familyId,
    String? displayName,
    String? baseUrl,
    String? modelName,
    bool? supportsVision,
    bool? supportsFunctions,
  }) {
    return ProviderConfig(
      id: id ?? this.id,
      presetId: presetId ?? this.presetId,
      familyId: familyId ?? this.familyId,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      modelName: modelName ?? this.modelName,
      supportsVision: supportsVision ?? this.supportsVision,
      supportsFunctions: supportsFunctions ?? this.supportsFunctions,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization (toMap/fromMap and toJson/fromJson are interchangeable).
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'preset_id': presetId,
      'family_id': familyId,
      'display_name': displayName,
      'base_url': baseUrl,
      'model_name': modelName,
      'supports_vision': supportsVision ? 1 : 0,
      'supports_functions': supportsFunctions ? 1 : 0,
    };
  }

  factory ProviderConfig.fromMap(Map<String, dynamic> map) {
    final Object? vision = map['supports_vision'];
    final Object? functions = map['supports_functions'];
    final String preset =
        (map['preset_id'] ?? map['presetId']) as String? ?? '';
    return ProviderConfig(
      id: map['id'] as String,
      presetId: preset,
      familyId: (map['family_id'] ?? map['familyId']) as String? ?? preset,
      displayName: map['display_name'] as String? ?? '',
      baseUrl: map['base_url'] as String? ?? '',
      modelName: map['model_name'] as String? ?? '',
      supportsVision: vision is int ? vision == 1 : vision == true,
      supportsFunctions: functions is int ? functions == 1 : functions == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'presetId': presetId,
        'familyId': familyId,
        'displayName': displayName,
        'baseUrl': baseUrl,
        'modelName': modelName,
        'supportsVision': supportsVision,
        'supportsFunctions': supportsFunctions,
      };

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    final String preset =
        (json['presetId'] ?? json['preset_id']) as String? ?? '';
    return ProviderConfig(
      id: json['id'] as String,
      presetId: preset,
      // Legacy configs without familyId fall back to presetId (ids coincide).
      familyId: (json['familyId'] ?? json['family_id']) as String? ?? preset,
      displayName: json['displayName'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
      modelName: json['modelName'] as String? ?? '',
      supportsVision: json['supportsVision'] as bool? ??
          (json['supports_vision'] == 1),
      supportsFunctions: json['supportsFunctions'] as bool? ??
          (json['supports_functions'] == 1),
    );
  }

  /// Encode a list of configs into a JSON string (for SharedPreferences).
  static String encodeList(List<ProviderConfig> configs) {
    return jsonEncode(
      configs.map((ProviderConfig c) => c.toJson()).toList(),
    );
  }

  /// Decode a JSON string into a list of configs (empty list on any error).
  static List<ProviderConfig> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return <ProviderConfig>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <ProviderConfig>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ProviderConfig.fromJson)
          .toList();
    } catch (_) {
      return <ProviderConfig>[];
    }
  }

  @override
  String toString() =>
      'ProviderConfig(id: $id, preset: $presetId, model: $modelName)';
}
