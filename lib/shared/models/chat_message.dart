/// Chat message model for the AI chat feature.
class ChatMessage {
  const ChatMessage({
    this.id,
    required this.role,
    required this.content,
    this.createdAt,
    this.error = false,
  });

  /// Database row id (null for unsaved items).
  final int? id;

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
    String? role,
    String? content,
    DateTime? createdAt,
    bool? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      error: error ?? this.error,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'role': role,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'error': error ? 1 : 0,
    };
  }

  factory ChatMessage.fromMap(Map<String, Object?> map) {
    return ChatMessage(
      id: map['id'] as int?,
      role: (map['role'] as String?) ?? roleUser,
      content: (map['content'] as String?) ?? '',
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      error: (map['error'] as int?) == 1,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'role': role,
        'content': content,
        'created_at': createdAt?.toIso8601String(),
        'error': error,
      };

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    return ChatMessage(
      id: json['id'] as int?,
      role: (json['role'] as String?) ?? roleUser,
      content: (json['content'] as String?) ?? '',
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      error: (json['error'] as bool?) ?? false,
    );
  }

  @override
  String toString() => 'ChatMessage(role: $role, content: $content)';
}
