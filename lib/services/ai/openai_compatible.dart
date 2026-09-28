import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../shared/models/chat_message.dart';
import 'ai_provider.dart';

/// AI provider for any OpenAI-compatible `/v1/chat/completions` endpoint:
/// OpenAI, OpenRouter, Together, LM Studio, Ollama (openai mode), etc.
class OpenAiCompatibleProvider implements AiProvider {
  OpenAiCompatibleProvider({
    required this.baseUrl,
    required this.apiKey,
    this.defaultModel = 'gpt-4o-mini',
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  final String name = 'OpenAI-compatible';

  /// API base URL, e.g. 'https://api.openai.com/v1'.
  final String baseUrl;

  /// Bearer token / API key.
  final String apiKey;

  /// Model used when none is passed to [chat].
  final String defaultModel;

  final http.Client _client;

  @override
  Future<bool> isConfigured() async {
    // TODO: реализация — проверить валидность ключа лёгким запросом
    // (например, GET {baseUrl}/models).
    return apiKey.isNotEmpty && baseUrl.isNotEmpty;
  }

  @override
  Future<String> chat(
    List<ChatMessage> messages, {
    String? systemPrompt,
    String? model,
    double temperature = 0.7,
  }) async {
    final List<Map<String, String>> payload = <Map<String, String>>[
      if (systemPrompt != null && systemPrompt.isNotEmpty)
        <String, String>{'role': ChatMessage.roleSystem, 'content': systemPrompt},
      ...messages.map((ChatMessage m) => <String, String>{
            'role': m.role,
            'content': m.content,
          }),
    ];

    // TODO: реализация — отправить POST {baseUrl}/chat/completions
    // с телом {"model": ..., "messages": payload, "temperature": ...}
    // и достать choices[0].message.content из ответа.
    final Uri uri = Uri.parse('$baseUrl/chat/completions');
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(<String, Object?>{
        'model': model ?? defaultModel,
        'messages': payload,
        'temperature': temperature,
      }),
    );

    if (response.statusCode != 200) {
      throw AiException(
        'Ошибка API (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final Map<String, Object?> data =
        jsonDecode(response.body) as Map<String, Object?>;
    final List<Object?> choices = data['choices'] as List<Object?>? ?? [];
    if (choices.isEmpty) {
      throw const AiException('Пустой ответ модели');
    }
    final Map<String, Object?> message =
        (choices.first as Map<String, Object?>)['message']
            as Map<String, Object?>? ??
        <String, Object?>{};
    return (message['content'] as String?) ?? '';
  }

  @override
  Future<Map<String, Object?>?> parseIntent(
    String input, {
    required List<String> allowedIntents,
  }) async {
    // TODO: реализация — попросить модель вернуть строгий JSON вида
    // {"intent": "...", "data": {...}} и распарсить его через jsonDecode.
    try {
      final String raw = await chat(
        <ChatMessage>[
          ChatMessage(
            role: ChatMessage.roleUser,
            content: input,
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt:
            'Верни строго JSON. Разрешённые intent: ${allowedIntents.join(", ")}.',
        temperature: 0.0,
      );
      return jsonDecode(raw) as Map<String, Object?>?;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _client.close();
  }
}
