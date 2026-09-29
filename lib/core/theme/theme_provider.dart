import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'app_theme.dart';

/// Theme state holder ([ChangeNotifier]).
///
/// Persists the selected seed (accent) color and dark/light mode choice
/// via [SharedPreferences].
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  bool _isDarkMode = true;
  int _seedColorValue = AppConstants.defaultSeedColor;
  bool _loaded = false;

  /// Whether the app currently uses the dark theme.
  bool get isDarkMode => _isDarkMode;

  /// Currently selected seed color as an ARGB int (e.g. 0xFF7C4DFF).
  int get seedColorValue => _seedColorValue;

  /// Currently selected seed color as a [Color].
  Color get seedColor => Color(_seedColorValue);

  /// Index of the current seed color inside [AppConstants.seedColors]
  /// (-1 if custom / unknown).
  int get seedColorIndex => AppConstants.seedColors.indexOf(_seedColorValue);

  /// True after [loadFromPrefs] has completed.
  bool get loaded => _loaded;

  /// Loads saved theme preferences. Safe to call multiple times.
  Future<void> loadFromPrefs() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final SharedPreferences p = _prefs!;

      _isDarkMode = p.getBool(AppConstants.prefIsDarkMode) ?? true;
      _seedColorValue =
          p.getInt(AppConstants.prefSeedColor) ?? AppConstants.defaultSeedColor;

      // Guard: if stored value is not in presets anymore, fall back to default.
      if (!AppConstants.seedColors.contains(_seedColorValue)) {
        _seedColorValue = AppConstants.defaultSeedColor;
      }
    } catch (e, s) {
      debugPrint('ThemeProvider.loadFromPrefs failed: $e\n$s');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Toggles between dark and light mode and persists the choice.
  Future<void> toggleDarkMode({bool? value}) async {
    _isDarkMode = value ?? !_isDarkMode;
    notifyListeners();
    await _save();
  }

  /// Sets the accent (seed) color from one of [AppConstants.seedColors].
  Future<void> setSeedColor(int colorValue) async {
    if (_seedColorValue == colorValue) return;
    _seedColorValue = colorValue;
    notifyListeners();
    await _save();
  }

  /// Convenience: set seed color by index in [AppConstants.seedColors].
  Future<void> setSeedColorByIndex(int index) async {
    if (index < 0 || index >= AppConstants.seedColors.length) return;
    await setSeedColor(AppConstants.seedColors[index]);
  }

  /// Builds the active [ThemeData] from current state.
  ThemeData get themeData => _isDarkMode
      ? AppTheme.dark(seedColorValue: _seedColorValue)
      : AppTheme.light(seedColorValue: _seedColorValue);

  Future<void> _save() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setBool(AppConstants.prefIsDarkMode, _isDarkMode);
      await _prefs!.setInt(AppConstants.prefSeedColor, _seedColorValue);
    } catch (e, s) {
      debugPrint('ThemeProvider._save failed: $e\n$s');
    }
  }
}
