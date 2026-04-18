import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/llm_provider.dart';
import '../services/llm_credentials_service.dart';

/// API Configuration for Contexta
/// Securely manages API keys and endpoints
class ApiConfig {
  // Private constructor to prevent instantiation
  ApiConfig._();

  /// Optional fallback env values for local developer workflows.
  static const String _fallbackEnvProviderKeyName = 'LLM_PROVIDER_NAME';
  static const String _fallbackEnvApiKeyName = 'LLM_API_KEY';

  /// Resolve active provider name from local user settings or env fallback.
  static Future<String> getActiveProviderName() async {
    final credentials = LlmCredentialsService();
    await credentials.initialize();

    final providerName = await credentials.getProviderName();
    if (LlmProviderRegistry.isConfigured(providerName)) {
      return providerName!.trim();
    }

    final envProvider = dotenv.env[_fallbackEnvProviderKeyName] ?? '';
    if (LlmProviderRegistry.isConfigured(envProvider)) {
      return envProvider.trim();
    }

    throw ApiKeyNotConfiguredException(
      'No provider configured. Add a provider name in Settings > AI provider & key.',
    );
  }

  /// Get active API key from secure user storage or env fallback.
  static Future<String> getActiveApiKey() async {
    final credentials = LlmCredentialsService();
    await credentials.initialize();

    final secureKey = await credentials.getApiKey();
    if (secureKey != null && secureKey.isNotEmpty) {
      return secureKey;
    }

    final envKey = dotenv.env[_fallbackEnvApiKeyName] ?? '';
    if (envKey.isNotEmpty && envKey != 'your_api_key_here') {
      return envKey;
    }

    throw ApiKeyNotConfiguredException(
      'No API key configured. Add your key in Settings > AI provider & key.',
    );
  }

  static Future<bool> get isProviderConfigured async {
    try {
      final provider = await getActiveProviderName();
      if (!LlmProviderRegistry.isConfigured(provider)) {
        return false;
      }
      LlmProviderRegistry.resolve(provider);
      return true;
    } on ApiKeyNotConfiguredException {
      return false;
    } on UnsupportedLlmProviderException {
      return false;
    }
  }

  /// Check if both provider and key are configured.
  static Future<bool> get isLlmConfigured async {
    try {
      final provider = await getActiveProviderName();
      final key = await getActiveApiKey();
      if (!LlmProviderRegistry.isConfigured(provider) || key.isEmpty) {
        return false;
      }
      LlmProviderRegistry.resolve(provider);
      return true;
    } on ApiKeyNotConfiguredException {
      return false;
    } on UnsupportedLlmProviderException {
      return false;
    }
  }

  /// Maximum tokens for explanation response
  static const int maxTokens = 300;

  /// Temperature for response creativity (lower = more focused)
  static const double temperature = 0.3;

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);
}

/// Exception thrown when API key is not configured
class ApiKeyNotConfiguredException implements Exception {
  final String message;
  ApiKeyNotConfiguredException(this.message);

  @override
  String toString() => 'ApiKeyNotConfiguredException: $message';
}
