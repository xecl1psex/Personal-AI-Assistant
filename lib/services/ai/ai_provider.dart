import '../../shared/models/chat_message.dart';

/// Abstract interface for any AI backend
/// (OpenAI-compatible APIs, local models, etc.).
///
/// Concrete implementations live in this folder
/// (e.g. `OpenAiCompatibleProvider` in openai_compatible.dart).
abstract class AiProvider {
  /// Human-readable provider name, e.g. 'OpenAI'.
  String get name;

  /// Whether the provider is configured (API key present, endpoint set).
  Future<bool> isConfigured();

  /// Sends a chat completion request.
  ///
  /// [messages] is the conversation history (chronological order).
  /// Returns assistant text answer. Throws [AiException] on failure.
  Future<String> chat(
    List<ChatMessage> messages, {
    String? systemPrompt,
    String? model,
    double temperature = 0.7,
  });

  /// Parses natural language into structured intents
  /// (e.g. transaction / task creation) using the LLM.
  ///
  /// Returns raw JSON as a [Map], or null if parsing failed.
  Future<Map<String, Object?>?> parseIntent(
    String input, {
    required List<String> allowedIntents,
  });

  /// Releases resources (HTTP clients, subscriptions).
  void dispose();
}

/// Error thrown by AI providers.
class AiException implements Exception {
  const AiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AiException(${statusCode ?? '-'}): $message';
}
