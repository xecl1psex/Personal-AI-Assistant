import '../../shared/models/provider_config.dart';
import 'ai_provider.dart';
import 'openai_compatible.dart';

/// Factory / facade that turns a [ProviderConfig] + API key into a usable
/// [AiProvider] instance. All current presets speak the OpenAI-compatible
/// protocol, so [OpenAiCompatibleProvider] covers every case.
class AiService {
  const AiService();

  /// Create a concrete provider for [config] using [apiKey].
  AiProvider createProvider(ProviderConfig config, String apiKey) {
    return OpenAiCompatibleProvider(
      baseUrl: config.baseUrl,
      modelName: config.modelName,
      apiKey: apiKey,
    );
  }

  /// Create a provider and run its lightweight connectivity check.
  ///
  /// Returns true on success. On failure rethrows [AiProviderException] with
  /// the full diagnostic text (HTTP code + server response body, or network
  /// error details) so the UI can display it to the user.
  Future<bool> testConnection(ProviderConfig config, String apiKey) async {
    final AiProvider provider = createProvider(config, apiKey);
    try {
      return await provider.testConnection();
    } finally {
      // Release the HTTP client if the implementation supports it.
      if (provider is OpenAiCompatibleProvider) {
        provider.dispose();
      }
    }
  }
}
