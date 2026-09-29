import 'package:flutter/foundation.dart';

import '../../services/ai/ai_provider.dart';
import '../../services/ai/ai_service.dart';
import '../../services/database/database_service.dart';
import '../../shared/models/chat_message.dart';
import '../../shared/models/provider_config.dart';
import '../settings/settings_provider.dart';

/// Conversation state for the AI chat screen.
///
/// * Keeps the message list of the current chat in memory and persists it
///   locally via [DatabaseService] (chats + messages tables).
/// * Sends requests through the active provider configured in
///   [SettingsProvider] (API key is read from secure storage on every send).
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    AiService? aiService,
    DatabaseService? db,
  })  : _aiService = aiService ?? const AiService(),
        _db = db ?? DatabaseService.instance;

  /// System prompt prepended to every request.
  static const String systemPrompt =
      'Ты — Personal AI, приватный ассистент пользователя. '
      'Отвечай кратко, по делу, на русском языке. '
      'Если не знаешь — скажи честно. Не выдумывай факты. '
      'Можешь помогать с учётом финансов, задачами и другими вопросами.';

  final AiService _aiService;
  final DatabaseService _db;

  int? _currentChatId;
  List<ChatMessage> _messages = <ChatMessage>[];
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Messages of the current chat (chronological order).
  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);

  /// True while waiting for an assistant reply.
  bool get isLoading => _isLoading;

  /// Last error text (null when there is no error).
  String? get errorMessage => _errorMessage;

  /// Id of the current conversation (null before [init] completes).
  int? get currentChatId => _currentChatId;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Ensure a chat exists and load its history from the local database.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final List<Map<String, dynamic>> chats =
          await _db.getAllChats();
      if (chats.isNotEmpty) {
        _currentChatId = chats.first['id'] as int?;
      } else {
        _currentChatId = await _db.createChat();
      }
      if (_currentChatId != null) {
        _messages = await _db.getMessages(_currentChatId!);
      }
    } catch (e, s) {
      debugPrint('ChatProvider.init failed: $e\n$s');
      _errorMessage = 'Не удалось загрузить историю чата: $e';
    } finally {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Send [text] to the active AI provider and append the answer.
  ///
  /// Persists both the user message and the assistant reply to the local DB.
  Future<void> sendMessage(String text, SettingsProvider settings) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _errorMessage = null;

    // Make sure we have a chat to write into.
    await init();
    if (_currentChatId == null) {
      _currentChatId = await _db.createChat();
    }
    final int chatId = _currentChatId!;

    // 1. User message -> memory + DB.
    final ChatMessage userMsg = ChatMessage(
      chatId: chatId,
      role: ChatMessage.roleUser,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    _messages = List<ChatMessage>.from(_messages)..add(userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      final int savedId = await _db.insertMessage(userMsg);
      _messages[_messages.length - 1] = userMsg.copyWith(id: savedId);

      // 2-4. Resolve active provider + API key.
      final ProviderConfig? config = settings.activeProvider;
      if (config == null) {
        throw StateError(
          'Провайдер ИИ не выбран. Зайдите в настройки и добавьте модель.',
        );
      }
      final String? apiKey = await settings.getApiKey(config.id);
      if (apiKey == null || apiKey.isEmpty) {
        throw StateError(
          'API-ключ не найден. Зайдите в настройки и добавьте ключ.',
        );
      }
      final AiProvider provider = _aiService.createProvider(config, apiKey);

      // 5. Request the completion (history WITHOUT transient/system rows).
      final List<ChatMessage> history = _messages
          .where((ChatMessage m) => !m.isSystem && !m.error)
          .toList(growable: false);
      final String answer = await provider.chat(
        history,
        systemPrompt: systemPrompt,
      );

      // 6. Assistant message -> memory + DB.
      final ChatMessage botMsg = ChatMessage(
        chatId: chatId,
        role: ChatMessage.roleAssistant,
        content: answer,
        createdAt: DateTime.now(),
      );
      _messages = List<ChatMessage>.from(_messages)..add(botMsg);
      final int botId = await _db.insertMessage(botMsg);
      _messages[_messages.length - 1] = botMsg.copyWith(id: botId);

      // Auto-title a fresh chat with the first user question.
      if (_messages.where((ChatMessage m) => m.isUser).length == 1) {
        final String title = trimmed.length <= 40
            ? trimmed
            : '${trimmed.substring(0, 40)}…';
        await _db.updateChatTitle(chatId, title);
      }
    } catch (e) {
      // 7. Surface the full error text to the UI.
      _errorMessage = e.toString();
    } finally {
      // 8. Reset loading state and repaint.
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete all messages of the current chat (DB + memory).
  Future<void> clearHistory() async {
    if (_currentChatId == null) return;
    try {
      await _db.clearChat(_currentChatId!);
    } catch (e) {
      _errorMessage = 'Не удалось очистить историю: $e';
    }
    _messages = <ChatMessage>[];
    _errorMessage = null;
    notifyListeners();
  }

  /// Dismiss the current error banner.
  void dismissError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
