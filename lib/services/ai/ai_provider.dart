import '../../shared/models/chat_message.dart';

/// Abstract interface for any AI backend
/// (OpenAI-compatible APIs, local models, etc.).
///
/// Concrete implementations live in this folder
/// (e.g. `OpenAiCompatibleProvider` in openai_compatible.dart).
abstract class AiProvider {
  /// Sends a chat completion request.
  ///
  /// [messages] is the conversation history (chronological order).
  /// Returns assistant text answer. Throws [AiProviderException] on failure.
  Future<String> chat(
    List<ChatMessage> messages, {
    String? systemPrompt,
  });

  /// Lightweight connectivity check (tiny completion request).
  /// Returns true if the endpoint + API key work, false otherwise.
  Future<bool> testConnection();
}

/// Error thrown by AI providers.
class AiProviderException implements Exception {
  const AiProviderException(
    this.message, {
    this.statusCode,
    this.errorDetails,
  });

  /// Human-readable error text (Russian) shown to the user.
  final String message;

  /// HTTP status code, when the failure came from an API response.
  final int? statusCode;

  /// Raw server response body / original error text for debugging.
  final String? errorDetails;

  @override
  String toString() => 'AiProviderException(${statusCode ?? '-'}): $message';
}

/// Backwards-compatible alias: older code may still refer to [AiException].
typedef AiException = AiProviderException;
