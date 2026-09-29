/// Chat message model for the AI chat feature.
class ChatMessage {
  const ChatMessage({
    this.id,
    this.chatId,
    required this.role,
    required this.content,
    this.createdAt,
    this.error = false,
  });

  /// Database row id (null for unsaved items).
  final int? id;

  /// Id of the parent chat conversation (null for unsaved items).
  final int? chatId;

  /// Message author role: 'user', 'assistant' or 'system'.
  final String role;

  /// Plain text content of the message.
  final String content;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// True if this message represents an error response.
  final bool error;

  static const String roleUser = 'user';
  static const String roleAssistant = 'assistant';
  static const String roleSystem = 'system';

  bool get isUser => role == roleUser;
  bool get isAssistant => role == roleAssistant;
  bool get isSystem => role == roleSystem;

  ChatMessage copyWith({
    int? id,
    int? chatId,
    String? role,
    String? content,
    DateTime? createdAt,
    bool? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      error: error ?? this.error,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'chat_id': chatId,
      'role': role,
      'content': content,
      'error': error ? 1 : 0,
      // SQLite stores timestamps as INTEGER (milliseconds since epoch).
      'created_at': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromMap(Map<String, Object?> map) {
    return ChatMessage(
      id: map['id'] as int?,
      chatId: map['chat_id'] as int?,
      role: (map['role'] as String?) ?? roleUser,
      content: (map['content'] as String?) ?? '',
      createdAt: _parseCreatedAt(map['created_at']),
      error: (map['error'] as int?) == 1,
    );
  }

  static DateTime? _parseCreatedAt(Object? raw) {
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      // Backwards compatibility with the old ISO-8601 format.
      final int? millis = int.tryParse(raw);
      if (millis != null) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      return DateTime.tryParse(raw);
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'chat_id': chatId,
        'role': role,
        'content': content,
        'created_at': createdAt?.millisecondsSinceEpoch,
        'error': error,
      };

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    return ChatMessage(
      id: json['id'] as int?,
      chatId: json['chat_id'] as int?,
      role: (json['role'] as String?) ?? roleUser,
      content: (json['content'] as String?) ?? '',
      createdAt: _parseCreatedAt(json['created_at']),
      error: (json['error'] as bool?) ?? false,
    );
  }

  @override
  String toString() => 'ChatMessage(role: $role, content: $content)';
}
