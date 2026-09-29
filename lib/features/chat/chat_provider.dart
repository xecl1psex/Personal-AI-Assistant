import 'package:flutter/foundation.dart';

import '../../services/ai/ai_provider.dart';
import '../../services/ai/ai_service.dart';
import '../../services/database/database_service.dart';
import '../../shared/models/chat_message.dart';
import '../../shared/models/provider_config.dart';
import '../settings/settings_provider.dart';

/// Formats a chat timestamp for the chats drawer:
///  * today        -> 'HH:mm' (e.g. '14:07')
///  * yesterday    -> 'Вчера'
///  * earlier this year or before -> '28 сен'
String formatChatDate(int timestamp) {
  final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime chatDay = DateTime(date.year, date.month, date.day);
  final int diff = today.difference(chatDay).inDays;

  if (diff == 0) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  } else if (diff == 1) {
    return 'Вчера';
  } else {
    const List<String> months = <String>[
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

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

  final AiService _aiService;
  final DatabaseService _db;

  int? _currentChatId;
  List<ChatMessage> _messages = <ChatMessage>[];
  List<Map<String, dynamic>> _chats = <Map<String, dynamic>>[];
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Messages of the current chat (chronological order).
  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);

  /// All chats (most recently updated first), raw DB rows:
  /// keys 'id' (int), 'title' (String), 'created_at' (int), 'updated_at' (int).
  List<Map<String, dynamic>> get chats =>
      List<Map<String, dynamic>>.unmodifiable(_chats);

  /// True if at least one chat exists.
  bool get hasChats => _chats.isNotEmpty;

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
      await loadChats();
      if (_chats.isNotEmpty) {
        _currentChatId = _chats.first['id'] as int?;
      } else {
        _currentChatId = await _db.createChat();
        await loadChats();
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
  // Chats list (multi-conversation support)
  // ---------------------------------------------------------------------------

  /// Load all chats (most recently updated first) into memory.
  Future<void> loadChats() async {
    try {
      _chats = await _db.getAllChats();
    } catch (e) {
      _errorMessage = 'Не удалось загрузить список чатов: $e';
    }
    notifyListeners();
  }

  /// Create a new empty chat and switch to it.
  Future<void> createNewChat() async {
    try {
      final int id = await _db.createChat();
      _currentChatId = id;
      _messages = <ChatMessage>[];
      _errorMessage = null;
      await loadChats();
    } catch (e) {
      _errorMessage = 'Не удалось создать чат: $e';
    }
    notifyListeners();
  }

  /// Switch the active conversation to [chatId] and load its messages.
  Future<void> switchToChat(int chatId) async {
    if (_currentChatId == chatId) return;
    try {
      _currentChatId = chatId;
      _messages = await _db.getMessages(chatId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Не удалось загрузить чат: $e';
    }
    notifyListeners();
  }

  /// Delete a chat. If it was the active one — switch to the first remaining
  /// chat, or create a fresh one when the list becomes empty.
  Future<void> deleteChat(int chatId) async {
    try {
      await _db.deleteChat(chatId);
      await loadChats();
      if (_currentChatId == chatId) {
        if (_chats.isNotEmpty) {
          final int nextId = _chats.first['id'] as int;
          _currentChatId = nextId;
          _messages = await _db.getMessages(nextId);
        } else {
          _currentChatId = await _db.createChat();
          _messages = <ChatMessage>[];
          await loadChats();
        }
      } else {
        _messages = List<ChatMessage>.unmodifiable(_messages).toList();
      }
    } catch (e) {
      _errorMessage = 'Не удалось удалить чат: $e';
    }
    notifyListeners();
  }

  /// Rename a chat by id and refresh the chats list.
  Future<void> renameChat(int chatId, String title) async {
    try {
      await _db.updateChatTitle(chatId, title);
      await loadChats();
    } catch (e) {
      _errorMessage = 'Не удалось переименовать чат: $e';
      notifyListeners();
    }
  }

  /// Rename the current chat if it still has the default title, using the
  /// first 30 characters of the first user message.
  Future<void> _autoTitleFromMessage(String text) async {
    if (_currentChatId == null) return;
    Map<String, dynamic>? currentRow;
    for (final Map<String, dynamic> c in _chats) {
      if (c['id'] == _currentChatId) {
        currentRow = c;
        break;
      }
    }
    final String? title = currentRow?['title'] as String?;
    if (title != null && title != 'Новый чат') return;

    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final String newTitle = trimmed.length <= 30
        ? trimmed
        : '${trimmed.substring(0, 30)}…';
    await _db.updateChatTitle(_currentChatId!, newTitle);
    await loadChats();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Send [text] to the active AI provider and append the answer.
  ///
  /// [systemPrompt] is taken from `SystemPromptProvider` by the caller and
  /// prepended to the request. Persists both the user message and the
  /// assistant reply to the local DB.
  Future<void> sendMessage(
    String text,
    SettingsProvider settings,
    String systemPrompt,
  ) async {
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
    final bool isFirstUserMessage = !_messages.any((ChatMessage m) => m.isUser);
    _messages = List<ChatMessage>.from(_messages)..add(userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      final int savedId = await _db.insertMessage(userMsg);
      _messages[_messages.length - 1] = userMsg.copyWith(id: savedId);

      // Auto-title a fresh chat right after the first user message is saved.
      if (isFirstUserMessage) {
        await _autoTitleFromMessage(trimmed);
      }

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

      // Keep the chats list fresh (updated_at ordering may have changed).
      await loadChats();
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
      await loadChats();
    } catch (e) {
      _errorMessage = 'Не удалось очистить историю: $e';
    }
    _messages = <ChatMessage>[];
    notifyListeners();
  }

  /// Dismiss the current error banner.
  void dismissError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
