import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../shared/models/chat_message.dart';
import 'ai_provider.dart';

/// AI provider for any OpenAI-compatible `/v1/chat/completions` endpoint:
/// OpenAI, Gemini (OpenAI-compat mode), DeepSeek, Groq, OpenRouter,
/// Ollama (openai mode), etc.
class OpenAiCompatibleProvider implements AiProvider {
  OpenAiCompatibleProvider({
    required this.baseUrl,
    required this.modelName,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// API base URL, e.g. 'https://api.openai.com/v1'.
  final String baseUrl;

  /// Model name sent in requests, e.g. 'gpt-6-astra'.
  final String modelName;

  /// Bearer token / API key.
  final String apiKey;

  final http.Client _client;

  /// Map an HTTP status code to a clear Russian error message.
  static String friendlyHttpMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Неверный API-ключ. Проверьте его в настройках.';
      case 403:
        return 'Доступ запрещён. Возможно, нужен VPN или ключ не подходит.';
      case 404:
        return 'Модель не найдена. Проверьте название модели.';
      case 429:
        return 'Слишком много запросов. Подождите минуту и попробуйте снова.';
      case 500:
      case 502:
      case 503:
        return 'Сервер перегружен. Попробуйте через пару минут.';
      default:
        return 'Ошибка API ($statusCode).';
    }
  }

  /// Build an [AiProviderException] for a failed HTTP response:
  /// user-friendly Russian text + raw server body in [errorDetails].
  static AiProviderException _httpException(http.Response response) {
    final String details = _truncate(response.body);
    return AiProviderException(
      '${friendlyHttpMessage(response.statusCode)} '
      '(HTTP ${response.statusCode})',
      statusCode: response.statusCode,
      errorDetails: details.isEmpty ? null : details,
    );
  }

  @override
  Future<String> chat(
    List<ChatMessage> messages, {
    String? systemPrompt,
  }) async {
    final List<Map<String, String>> payload = <Map<String, String>>[
      if (systemPrompt != null && systemPrompt.isNotEmpty)
        <String, String>{
          'role': ChatMessage.roleSystem,
          'content': systemPrompt,
        },
      ...messages.map((ChatMessage m) => <String, String>{
            'role': m.role,
            'content': m.content,
          }),
    ];

    final Uri uri = Uri.parse('$baseUrl/chat/completions');
    const int maxAttempts = 3;
    late final http.Response response;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        response = await _client.post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(<String, Object?>{
            'model': modelName,
            'messages': payload,
            'stream': false,
          }),
        ).timeout(const Duration(seconds: 60));
      } on TimeoutException {
        throw const AiProviderException(
          'Сервер не ответил за 60 секунд. Проверьте интернет.',
          errorDetails: 'TimeoutException',
        );
      } on SocketException catch (e) {
        final String osError = e.osError?.message ?? e.message;
        throw AiProviderException(
          'Нет интернета. Проверьте подключение. ($baseUrl)',
          errorDetails:
              'SocketException: $osError. На Android-эмуляторе localhost '
              'недоступен — используйте 10.0.2.2.',
        );
      } on http.ClientException catch (e) {
        throw AiProviderException(
          'Сетевая ошибка: ${e.message}',
          errorDetails: 'ClientException: ${e.message}',
        );
      }

      // Retry on HTTP 503 (rate limited / temporarily unavailable): up to 3
      // attempts with a 2 second pause between them.
      if (response.statusCode == 503 && attempt < maxAttempts - 1) {
        await Future<void>.delayed(const Duration(seconds: 2));
        continue;
      }
      break;
    }

    if (response.statusCode != 200) {
      throw _httpException(response);
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> choices =
        (data['choices'] as List<dynamic>?) ?? <dynamic>[];
    if (choices.isEmpty) {
      throw const AiProviderException('Пустой ответ модели');
    }
    final Map<String, dynamic> message =
        (choices.first as Map<String, dynamic>)['message']
            as Map<String, dynamic>? ??
        <String, dynamic>{};
    return (message['content'] as String?) ?? '';
  }

  /// Lightweight connectivity check: sends a single 'ping' message with
  /// max_tokens = 5.
  ///
  /// Returns true on HTTP 200. On any failure throws [AiProviderException]
  /// containing the full diagnostic text: HTTP status code + server response
  /// body, or the underlying network error (SocketException, TimeoutException,
  /// ClientException, ...).
  @override
  Future<bool> testConnection() async {
    final Uri uri = Uri.parse('$baseUrl/chat/completions');
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(<String, Object?>{
              'model': modelName,
              'messages': <Map<String, String>>[
                <String, String>{
                  'role': ChatMessage.roleUser,
                  'content': 'ping',
                },
              ],
              'max_tokens': 5,
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const AiProviderException(
        'Сервер не ответил за 60 секунд. Проверьте интернет.',
        errorDetails: 'TimeoutException',
      );
    } on SocketException catch (e) {
      final String osError = e.osError?.message ?? e.message;
      throw AiProviderException(
        'Нет интернета. Проверьте подключение. ($baseUrl)',
        errorDetails:
            'SocketException: $osError. На Android-эмуляторе localhost '
            'недоступен — используйте 10.0.2.2.',
      );
    } on http.ClientException catch (e) {
      throw AiProviderException(
        'Сетевая ошибка: ${e.message}',
        errorDetails: 'ClientException: ${e.message}',
      );
    }

    if (response.statusCode != 200) {
      throw _httpException(response);
    }
    return true;
  }

  static String _truncate(String text, {int maxLength = 500}) {
    final String trimmed = text.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength)}…';
  }

  /// Releases the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
