import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme/theme_provider.dart';

/// Entry point of the Personal AI app.
///
/// Initializes Flutter bindings, loads persisted theme preferences
/// (accent color + dark mode) *before* the first frame, then runs
/// [PersonalAiApp] wrapped in a [ChangeNotifierProvider] for [ThemeProvider].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ThemeProvider themeProvider = ThemeProvider();
  // Restore saved theme so the very first frame already uses the right
  // accent color / brightness (no flash of default theme).
  await themeProvider.loadFromPrefs();

  runApp(
    ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: const PersonalAiApp(),
    ),
  );
}
