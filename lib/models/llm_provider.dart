enum LlmTransport { gemini, openAiCompatible, anthropic }

class UnsupportedLlmProviderException implements Exception {
  final String providerName;

  UnsupportedLlmProviderException(this.providerName);

  @override
  String toString() {
    return 'UnsupportedLlmProviderException: Unsupported provider "$providerName". '
        'Use a supported provider name or a full API base URL/domain for an OpenAI-compatible provider.';
  }
}

/// Resolved provider profile inferred from user-entered provider name.
class LlmProviderProfile {
  final String providerName;
  final String displayName;
  final LlmTransport transport;
  final String baseUrl;
  final String endpoint;
  final String model;

  const LlmProviderProfile({
    required this.providerName,
    required this.displayName,
    required this.transport,
    required this.baseUrl,
    required this.endpoint,
    required this.model,
  });
}

class LlmProviderRegistry {
  LlmProviderRegistry._();

  static String normalizeProviderName(String? providerName) {
    return providerName?.trim() ?? '';
  }

  static bool isConfigured(String? providerName) {
    return normalizeProviderName(providerName).isNotEmpty;
  }

  /// Resolve transport and default model from a free-form provider name.
  static LlmProviderProfile resolve(String providerNameInput) {
    final providerName = normalizeProviderName(providerNameInput);
    final normalized = providerName.toLowerCase();

    if (normalized.contains('gemini') || normalized == 'google') {
      return const LlmProviderProfile(
        providerName: 'Gemini',
        displayName: 'Gemini',
        transport: LlmTransport.gemini,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        endpoint: '/models/gemini-2.0-flash:generateContent',
        model: 'gemini-2.0-flash',
      );
    }

    if (normalized.contains('perplexity')) {
      return const LlmProviderProfile(
        providerName: 'Perplexity',
        displayName: 'Perplexity',
        transport: LlmTransport.openAiCompatible,
        baseUrl: 'https://api.perplexity.ai',
        endpoint: '/chat/completions',
        model: 'sonar',
      );
    }

    if (normalized.contains('openrouter')) {
      return const LlmProviderProfile(
        providerName: 'OpenRouter',
        displayName: 'OpenRouter',
        transport: LlmTransport.openAiCompatible,
        baseUrl: 'https://openrouter.ai/api',
        endpoint: '/v1/chat/completions',
        model: 'openai/gpt-4o-mini',
      );
    }

    if (normalized.contains('groq')) {
      return const LlmProviderProfile(
        providerName: 'Groq',
        displayName: 'Groq',
        transport: LlmTransport.openAiCompatible,
        baseUrl: 'https://api.groq.com/openai',
        endpoint: '/v1/chat/completions',
        model: 'llama-3.1-8b-instant',
      );
    }

    if (normalized.contains('mistral')) {
      return const LlmProviderProfile(
        providerName: 'Mistral',
        displayName: 'Mistral',
        transport: LlmTransport.openAiCompatible,
        baseUrl: 'https://api.mistral.ai',
        endpoint: '/v1/chat/completions',
        model: 'mistral-small-latest',
      );
    }

    if (normalized.contains('deepseek')) {
      return const LlmProviderProfile(
        providerName: 'DeepSeek',
        displayName: 'DeepSeek',
        transport: LlmTransport.openAiCompatible,
        baseUrl: 'https://api.deepseek.com',
        endpoint: '/v1/chat/completions',
        model: 'deepseek-chat',
      );
    }

    if (normalized.contains('anthropic') || normalized.contains('claude')) {
      return const LlmProviderProfile(
        providerName: 'Anthropic',
        displayName: 'Anthropic',
        transport: LlmTransport.anthropic,
        baseUrl: 'https://api.anthropic.com',
        endpoint: '/v1/messages',
        model: 'claude-3-5-sonnet-latest',
      );
    }

    if (normalized.contains('openai')) {
      return const LlmProviderProfile(
        providerName: 'OpenAI',
        displayName: 'OpenAI',
        transport: LlmTransport.openAiCompatible,
        baseUrl: 'https://api.openai.com',
        endpoint: '/v1/chat/completions',
        model: 'gpt-4o-mini',
      );
    }

    if (_looksLikeUrlOrDomain(providerName)) {
      final fallbackBase = _inferOpenAiCompatibleBaseUrl(providerName);
      return LlmProviderProfile(
        providerName: providerName,
        displayName: providerName,
        transport: LlmTransport.openAiCompatible,
        baseUrl: fallbackBase,
        endpoint: '/v1/chat/completions',
        model: 'gpt-4o-mini',
      );
    }

    throw UnsupportedLlmProviderException(providerName);
  }

  static bool _looksLikeUrlOrDomain(String providerName) {
    final trimmed = providerName.trim();
    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.contains('.');
  }

  static String _inferOpenAiCompatibleBaseUrl(String providerName) {
    final trimmed = providerName.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed.endsWith('/')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed;
    }

    if (trimmed.contains('.')) {
      return 'https://$trimmed';
    }

    throw UnsupportedLlmProviderException(providerName);
  }
}
