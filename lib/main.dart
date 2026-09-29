import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme/theme_provider.dart';
import 'features/chat/chat_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/settings/system_prompt_provider.dart';

/// Entry point of the Personal AI app.
///
/// Initializes Flutter bindings, then runs [PersonalAiApp] wrapped in a
/// [MultiProvider] with:
///  * [ThemeProvider] — dark theme + accent color (loaded from prefs).
///  * [SettingsProvider] — AI providers list, active provider, API keys.
///  * [ChatProvider] — conversation state + persistence.
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider()..loadFromPrefs(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider()..load(),
        ),
        ChangeNotifierProvider<SystemPromptProvider>(
          create: (_) => SystemPromptProvider()..load(),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(),
        ),
      ],
      child: const PersonalAiApp(),
    ),
  );
}
