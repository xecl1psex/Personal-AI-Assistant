/// Presets of AI providers / endpoints available in Settings.
///
/// Each preset describes an OpenAI-compatible backend the user can add.
class ModelPreset {
  const ModelPreset({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.defaultModel,
    required this.docsUrl,
    this.supportsVision = false,
    this.supportsFunctions = false,
  });

  /// Unique stable id ('gemini', 'openai', ...). Used as presetId in
  /// [ProviderConfig].
  final String id;

  /// Display name in UI.
  final String name;

  /// OpenAI-compatible API base URL.
  final String baseUrl;

  /// Default model name for this endpoint.
  final String defaultModel;

  /// Where the user can obtain an API key / read documentation.
  final String docsUrl;

  /// Whether the default model accepts image input.
  final bool supportsVision;

  /// Whether the default model supports function / tool calling.
  final bool supportsFunctions;

  /// Convenience alias for [name] (kept for older call sites).
  String get label => name;

  /// Convenience alias for [defaultModel] (kept for older call sites).
  String get model => defaultModel;

  /// Ollama runs locally and does not require a real API key.
  bool get isLocal => id == 'ollama';

  /// Whether a remote API key is required to use this preset.
  bool get needsApiKey => !isLocal;
}

/// Static catalogue of provider presets.
class ModelPresets {
  ModelPresets._();

  /// Actual model catalogue as of September 2026.
  static const List<ModelPreset> allPresets = <ModelPreset>[
    ModelPreset(
      id: 'gemini',
      name: 'Gemini 3.8 Flash',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      defaultModel: 'gemini-3.8-flash',
      docsUrl: 'https://aistudio.google.com/apikey',
      supportsVision: true,
      supportsFunctions: true,
    ),
    ModelPreset(
      id: 'gemini-lite',
      name: 'Gemini 3.5 Flash-Lite',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      defaultModel: 'gemini-3.5-flash-lite',
      docsUrl: 'https://aistudio.google.com/apikey',
      supportsVision: true,
      supportsFunctions: true,
    ),
    ModelPreset(
      id: 'openai',
      name: 'OpenAI GPT-6 Astra',
      baseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-6-astra',
      docsUrl: 'https://platform.openai.com/api-keys',
      supportsVision: true,
      supportsFunctions: true,
    ),
    ModelPreset(
      id: 'openai-sol',
      name: 'OpenAI GPT-6 Sol',
      baseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-6-sol',
      docsUrl: 'https://platform.openai.com/api-keys',
      supportsVision: true,
      supportsFunctions: true,
    ),
    ModelPreset(
      id: 'claude',
      name: 'Claude Sonnet 5.5',
      baseUrl: 'https://api.anthropic.com/v1',
      defaultModel: 'claude-sonnet-5.5',
      docsUrl: 'https://console.anthropic.com/settings/keys',
      supportsVision: true,
      supportsFunctions: true,
    ),
    ModelPreset(
      id: 'deepseek',
      name: 'DeepSeek V4.1 Flash',
      baseUrl: 'https://api.deepseek.com/v1',
      defaultModel: 'deepseek-flash',
      docsUrl: 'https://platform.deepseek.com/api_keys',
      supportsFunctions: true,
    ),
    ModelPreset(
      id: 'groq',
      name: 'Groq Llama 4 Scout',
      baseUrl: 'https://api.groq.com/openai/v1',
      defaultModel:
          'groq/meta-llama/llama-4-scout-17b-16e-instruct',
      docsUrl: 'https://console.groq.com/keys',
      supportsFunctions: true,
    ),
    ModelPreset(
      id: 'openrouter',
      name: 'OpenRouter (любая модель)',
      baseUrl: 'https://openrouter.ai/api/v1',
      defaultModel: 'openai/gpt-6-astra',
      docsUrl: 'https://openrouter.ai/keys',
      supportsVision: true,
      supportsFunctions: true,
    ),
    ModelPreset(
      id: 'ollama',
      name: 'Ollama (локально)',
      baseUrl: 'http://localhost:11434/v1',
      defaultModel: 'gemma4',
      docsUrl: 'https://ollama.com',
    ),
  ];

  /// Alias kept for older call sites.
  static const List<ModelPreset> all = allPresets;

  /// Find preset by [id]; returns null if not found.
  static ModelPreset? findById(String? id) {
    if (id == null) return null;
    for (final ModelPreset p in allPresets) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Find preset by [id]; falls back to the first one.
  static ModelPreset byId(String? id) {
    return findById(id) ?? allPresets.first;
  }
}
