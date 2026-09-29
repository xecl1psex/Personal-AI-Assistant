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
    late final http.Response response;
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
      );
    } on http.ClientException catch (e) {
      throw AiProviderException('Сетевая ошибка: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw AiProviderException(
        'Ошибка API (${response.statusCode}): ${response.body}',
        statusCode: response.statusCode,
      );
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
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AiProviderException(
        'TimeoutException: сервер не ответил за 15 секунд. '
        'Проверьте URL и доступность сети.',
      );
    } on SocketException catch (e) {
      throw AiProviderException(
        'SocketException: ${e.osError?.message ?? e.message}. '
        'Устройство не может подключиться к $baseUrl '
        '(на Android localhost эмулятора недоступен — используйте 10.0.2.2).',
      );
    } on http.ClientException catch (e) {
      throw AiProviderException('Сетевая ошибка (ClientException): ${e.message}');
    }

    if (response.statusCode != 200) {
      throw AiProviderException(
        'HTTP ${response.statusCode}: ${_truncate(response.body)}',
        statusCode: response.statusCode,
      );
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
