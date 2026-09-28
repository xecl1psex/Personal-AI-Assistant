/// Global application constants: storage keys, colors, presets.
library constants;

class AppConstants {
  AppConstants._();

  /// Application name.
  static const String appName = 'Personal AI';

  // ---------------------------------------------------------------------------
  // SharedPreferences keys
  // ---------------------------------------------------------------------------
  static const String prefSeedColor = 'theme_seed_color';
  static const String prefIsDarkMode = 'theme_is_dark';
  static const String prefOnboardingCompleted = 'onboarding_completed';

  // ---------------------------------------------------------------------------
  // Secure storage keys
  // ---------------------------------------------------------------------------
  static const String secureApiKeyOpenAi = 'api_key_openai';
  static const String secureApiKeyAnthropic = 'api_key_anthropic';
  static const String secureApiKeyLocal = 'api_key_local';

  // ---------------------------------------------------------------------------
  // Base dark theme colors
  // ---------------------------------------------------------------------------
  static const int baseBackground = 0xFF0E0E11;
  static const int baseSurface = 0xFF17171C;

  /// 8 preset accent (seed) colors for Material 3 dynamic theming.
  static const List<int> seedColors = <int>[
    0xFF7C4DFF, // violet
    0xFF00BFA5, // teal
    0xFF00B0FF, // blue
    0xFFFF5252, // red
    0xFFFFAB40, // orange
    0xFFE040FB, // pink / fuchsia
    0xFF64DD17, // green / lime
    0xFF536DFE, // indigo
  ];

  /// Human-readable names of [seedColors] (same order).
  static const List<String> seedColorNames = <String>[
    'Фиолетовый',
    'Бирюзовый',
    'Синий',
    'Красный',
    'Оранжевый',
    'Розовый',
    'Зелёный',
    'Индиго',
  ];

  /// Default seed color (first preset).
  static const int defaultSeedColor = 0xFF7C4DFF;

  /// Database.
  static const String databaseName = 'personal_ai.db';
  static const int databaseVersion = 1;
}
