import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration for Contexta
/// Securely manages API keys and endpoints
class ApiConfig {
  // Private constructor to prevent instantiation
  ApiConfig._();

  /// Perplexity API base URL
  static const String perplexityBaseUrl = 'https://api.perplexity.ai';

  /// Perplexity chat completions endpoint
  static const String chatCompletionsEndpoint = '/chat/completions';

  /// Get the Perplexity API key from environment
  static String get perplexityApiKey {
    final key = dotenv.env['PERPLEXITY_API_KEY'] ?? '';
    if (key.isEmpty || key == 'your_api_key_here') {
      throw ApiKeyNotConfiguredException(
        'Perplexity API key not configured. '
        'Please add your API key to the .env file.',
      );
    }
    return key;
  }

  /// Check if the API key is properly configured
  static bool get isApiKeyConfigured {
    final key = dotenv.env['PERPLEXITY_API_KEY'] ?? '';
    return key.isNotEmpty && key != 'your_api_key_here';
  }

  /// Model to use for word explanations
  /// Using sonar for fast, concise responses
  static const String perplexityModel = 'sonar';

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
