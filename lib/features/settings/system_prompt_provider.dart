import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user-configurable system prompt sent with every AI request.
///
/// The value is persisted in [SharedPreferences] under the key
/// 'system_prompt'. When unset or blank, [defaultPrompt] is used.
class SystemPromptProvider extends ChangeNotifier {
  static const String _key = 'system_prompt';

  static const String defaultPrompt =
      'Ты — Personal AI, приватный ассистент пользователя. '
      'Отвечай кратко, по делу, на русском языке. '
      'Если не знаешь — скажи честно. Не выдумывай факты.';

  String _prompt = defaultPrompt;

  /// Current system prompt (never empty).
  String get prompt => _prompt;

  /// Load the saved prompt from preferences (falls back to [defaultPrompt]).
  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _prompt = prefs.getString(_key) ?? defaultPrompt;
    notifyListeners();
  }

  /// Persist a custom prompt. Blank values reset to [defaultPrompt].
  Future<void> setPrompt(String value) async {
    _prompt = value.trim().isEmpty ? defaultPrompt : value.trim();
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _prompt);
  }

  /// Reset the prompt to [defaultPrompt] and remove the stored override.
  Future<void> reset() async {
    _prompt = defaultPrompt;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
