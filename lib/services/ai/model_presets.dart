/// Presets of AI models / endpoints available in Settings.
///
/// Each preset describes an OpenAI-compatible backend the user can pick.
class ModelPreset {
  const ModelPreset({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.model,
    this.needsApiKey = true,
    this.isLocal = false,
  });

  /// Unique stable id (stored in preferences).
  final String id;

  /// Display name in UI.
  final String label;

  /// API base URL (OpenAI-compatible).
  final String baseUrl;

  /// Default model name for this endpoint.
  final String model;

  /// Whether a remote API key is required.
  final bool needsApiKey;

  /// Whether this preset points to a local (on-device / LAN) server.
  final bool isLocal;
}

/// Static catalogue of presets.
class ModelPresets {
  ModelPresets._();

  static const List<ModelPreset> all = <ModelPreset>[
    ModelPreset(
      id: 'openai_gpt4o_mini',
      label: 'OpenAI · GPT-4o mini',
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4o-mini',
    ),
    ModelPreset(
      id: 'openai_gpt4o',
      label: 'OpenAI · GPT-4o',
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4o',
    ),
    ModelPreset(
      id: 'openrouter_llama',
      label: 'OpenRouter · Llama 3.1 8B',
      baseUrl: 'https://openrouter.ai/api/v1',
      model: 'meta-llama/llama-3.1-8b-instruct',
    ),
    ModelPreset(
      id: 'ollama_local',
      label: 'Ollama (локально) · Llama 3.1',
      baseUrl: 'http://127.0.0.1:11434/v1',
      model: 'llama3.1',
      needsApiKey: false,
      isLocal: true,
    ),
    ModelPreset(
      id: 'lmstudio_local',
      label: 'LM Studio (локально)',
      baseUrl: 'http://127.0.0.1:1234/v1',
      model: 'local-model',
      needsApiKey: false,
      isLocal: true,
    ),
  ];

  /// Find preset by [id]; falls back to the first one.
  static ModelPreset byId(String? id) {
    return all.firstWhere(
      (ModelPreset p) => p.id == id,
      orElse: () => all.first,
    );
  }
}
