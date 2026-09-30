/// AI provider "families": one family = one API key + a list of models.
///
/// Replaces the old flat [ModelPreset] catalog: instead of adding every
/// model as a separate provider with its own key, the user adds a family
/// (e.g. "Google Gemini") once and can switch between the models inside it.
class ModelOption {
  const ModelOption({
    required this.id,
    required this.name,
    this.description,
    this.recommended = false,
  });

  /// Model id sent to the API, e.g. 'gemini-3.8-flash'.
  final String id;

  /// Human-readable name, e.g. 'Gemini 3.8 Flash'.
  final String name;

  /// Short description shown under the name, e.g. 'Мощная и быстрая'.
  final String? description;

  /// True for the best/default model of the family.
  final bool recommended;
}

/// A family of OpenAI-compatible models sharing one base URL and one API key.
class ProviderFamily {
  const ProviderFamily({
    required this.id,
    required this.name,
    required this.icon,
    required this.baseUrl,
    required this.docsUrl,
    required this.models,
    this.supportsVision = false,
    this.supportsFunctions = false,
    this.requiresApiKey = true,
  });

  /// Stable family id, e.g. 'gemini', 'openai', 'ollama'.
  final String id;

  /// Display name, e.g. 'Google Gemini'.
  final String name;

  /// Emoji icon shown in lists.
  final String icon;

  /// OpenAI-compatible base URL for the family's API.
  final String baseUrl;

  /// Where the user can obtain an API key.
  final String docsUrl;

  /// Models available inside this family.
  final List<ModelOption> models;

  /// Whether the family's models accept image input.
  final bool supportsVision;

  /// Whether the family's models support function / tool calling.
  final bool supportsFunctions;

  /// False for local providers (Ollama) that need no API key.
  final bool requiresApiKey;

  /// The default (recommended) model of the family, or the first one.
  ModelOption get defaultModel =>
      models.firstWhere(
        (ModelOption m) => m.recommended,
        orElse: () => models.first,
      );

  /// True when this family points at a local endpoint.
  bool get isLocal => !requiresApiKey;
}

/// Static catalog of all supported provider families.
class ProviderFamilies {
  const ProviderFamilies._();

  static const List<ProviderFamily> all = <ProviderFamily>[
    ProviderFamily(
      id: 'gemini',
      name: 'Google Gemini',
      icon: '✨',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      docsUrl: 'https://aistudio.google.com/apikey',
      supportsVision: true,
      supportsFunctions: true,
      requiresApiKey: true,
      models: <ModelOption>[
        ModelOption(
          id: 'gemini-3.8-flash',
          name: 'Gemini 3.8 Flash',
          description: 'Мощная и быстрая',
          recommended: true,
        ),
        ModelOption(
          id: 'gemini-3.5-flash-lite',
          name: 'Gemini 3.5 Flash-Lite',
          description: 'Самая быстрая',
        ),
        ModelOption(
          id: 'gemini-3.1-pro',
          name: 'Gemini 3.1 Pro',
          description: 'Для сложных задач',
        ),
      ],
    ),
    ProviderFamily(
      id: 'openai',
      name: 'OpenAI',
      icon: '🟢',
      baseUrl: 'https://api.openai.com/v1',
      docsUrl: 'https://platform.openai.com/api-keys',
      supportsVision: true,
      supportsFunctions: true,
      requiresApiKey: true,
      models: <ModelOption>[
        ModelOption(
          id: 'gpt-6-astra',
          name: 'GPT-6 Astra',
          description: 'Флагман',
          recommended: true,
        ),
        ModelOption(
          id: 'gpt-6-sol',
          name: 'GPT-6 Sol',
          description: 'Баланс',
        ),
        ModelOption(
          id: 'gpt-6-luna',
          name: 'GPT-6 Luna',
          description: 'Дешёвая',
        ),
      ],
    ),
    ProviderFamily(
      id: 'claude',
      name: 'Anthropic Claude',
      icon: '🟣',
      baseUrl: 'https://api.anthropic.com/v1',
      docsUrl: 'https://console.anthropic.com/settings/keys',
      supportsVision: true,
      supportsFunctions: true,
      requiresApiKey: true,
      models: <ModelOption>[
        ModelOption(
          id: 'claude-sonnet-5.5',
          name: 'Claude Sonnet 5.5',
          description: 'Универсальная',
          recommended: true,
        ),
        ModelOption(
          id: 'claude-opus-5.5',
          name: 'Claude Opus 5.5',
          description: 'Максимум мощности',
        ),
        ModelOption(
          id: 'claude-haiku-5.5',
          name: 'Claude Haiku 5.5',
          description: 'Быстрая',
        ),
      ],
    ),
    ProviderFamily(
      id: 'deepseek',
      name: 'DeepSeek',
      icon: '🐳',
      baseUrl: 'https://api.deepseek.com/v1',
      docsUrl: 'https://platform.deepseek.com/api_keys',
      supportsVision: false,
      supportsFunctions: true,
      requiresApiKey: true,
      models: <ModelOption>[
        ModelOption(
          id: 'deepseek-chat',
          name: 'DeepSeek V4.1 Flash',
          description: 'Основная',
          recommended: true,
        ),
        ModelOption(
          id: 'deepseek-v4-pro',
          name: 'DeepSeek V4 Pro',
          description: 'Мощная',
        ),
      ],
    ),
    ProviderFamily(
      id: 'groq',
      name: 'Groq',
      icon: '⚡',
      baseUrl: 'https://api.groq.com/openai/v1',
      docsUrl: 'https://console.groq.com/keys',
      supportsVision: false,
      supportsFunctions: true,
      requiresApiKey: true,
      models: <ModelOption>[
        ModelOption(
          id: 'llama-3.3-70b-versatile',
          name: 'Llama 3.3 70B',
          description: 'Быстрая и умная',
          recommended: true,
        ),
        ModelOption(
          id: 'llama-4-scout-17b-16e-instruct',
          name: 'Llama 4 Scout 17B',
          description: 'Новейшая',
        ),
      ],
    ),
    ProviderFamily(
      id: 'openrouter',
      name: 'OpenRouter',
      icon: '🌐',
      baseUrl: 'https://openrouter.ai/api/v1',
      docsUrl: 'https://openrouter.ai/keys',
      supportsVision: true,
      supportsFunctions: true,
      requiresApiKey: true,
      models: <ModelOption>[
        ModelOption(
          id: 'deepseek/deepseek-r1:free',
          name: 'DeepSeek R1 (free)',
          description: 'Бесплатная',
          recommended: true,
        ),
        ModelOption(
          id: 'openai/gpt-4o-mini',
          name: 'GPT-4o mini',
          description: 'Дёшево',
        ),
        ModelOption(
          id: 'anthropic/claude-3.5-sonnet',
          name: 'Claude 3.5 Sonnet',
        ),
      ],
    ),
    ProviderFamily(
      id: 'ollama',
      name: 'Ollama (локально)',
      icon: '🦙',
      baseUrl: 'http://10.0.2.2:11434/v1',
      docsUrl: 'https://ollama.com',
      supportsVision: false,
      supportsFunctions: false,
      requiresApiKey: false,
      models: <ModelOption>[
        ModelOption(
          id: 'llama3.2',
          name: 'Llama 3.2',
          recommended: true,
        ),
        ModelOption(
          id: 'gemma2',
          name: 'Gemma 2',
        ),
        ModelOption(
          id: 'qwen2.5',
          name: 'Qwen 2.5',
        ),
      ],
    ),
  ];

  /// Find a family by its stable id (null if unknown).
  static ProviderFamily? findById(String id) {
    for (final ProviderFamily f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}
