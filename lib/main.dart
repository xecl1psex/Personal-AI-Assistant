import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme/theme_provider.dart';
import 'features/settings/settings_provider.dart';

/// Entry point of the Personal AI app.
///
/// Initializes Flutter bindings, then runs [PersonalAiApp] wrapped in a
/// [MultiProvider] with:
///  * [ThemeProvider] — dark theme + accent color (loaded from prefs).
///  * [SettingsProvider] — AI providers list, active provider, API keys.
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
      ],
      child: const PersonalAiApp(),
    ),
  );
}
