import 'dart:async';
import '../config/api_config.dart';
import '../models/ai_request_error.dart';
import '../models/explanation_level.dart';
import 'connectivity_service.dart';
import 'llm_gateway_service.dart';
import 'word_explanation_cache_service.dart';

/// Result class for word explanation API calls.
class WordExplanationResult {
  final bool success;
  final String? explanation;
  final String? error;
  final AiRequestErrorType errorType;
  final String source; // 'cache', 'api', or 'error'

  const WordExplanationResult._({
    required this.success,
    this.explanation,
    this.error,
    this.errorType = AiRequestErrorType.none,
    this.source = 'api',
  });

  factory WordExplanationResult.success(
    String explanation, {
    String source = 'api',
  }) {
    return WordExplanationResult._(
      success: true,
      explanation: explanation,
      source: source,
    );
  }

  factory WordExplanationResult.failure(
    String error, {
    AiRequestErrorType errorType = AiRequestErrorType.unknown,
  }) {
    return WordExplanationResult._(
      success: false,
      error: error,
      errorType: errorType,
      source: 'error',
    );
  }

  bool get isFromCache => source == 'cache';
}

/// Service for contextual word explanations via user-configured LLM provider.
class LlmExplanationService {
  static final LlmExplanationService _instance =
      LlmExplanationService._internal();
  factory LlmExplanationService() => _instance;
  LlmExplanationService._internal();

  final LlmGatewayService _llmGateway = LlmGatewayService();
  final WordExplanationCacheService _cache = WordExplanationCacheService();
  final ConnectivityService _connectivity = ConnectivityService();

  Future<WordExplanationResult> explainWord({
    required String word,
    required String bookTitle,
    required String bookAuthor,
    ExplanationLevel level = ExplanationLevel.simple,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = '${word.toLowerCase()}_${level.name}';

      if (!forceRefresh) {
        final cacheResult = await _cache.getExplanation(
          word: cacheKey,
          bookTitle: bookTitle,
          bookAuthor: bookAuthor,
        );

        if (cacheResult.hit && cacheResult.explanation != null) {
          return WordExplanationResult.success(
            cacheResult.explanation!,
            source: 'cache',
          );
        }
      }

      final isOnline = _connectivity.isOnline;
      if (!isOnline) {
        final cacheResult = await _cache.getExplanation(
          word: cacheKey,
          bookTitle: bookTitle,
          bookAuthor: bookAuthor,
        );

        if (cacheResult.hit && cacheResult.explanation != null) {
          return WordExplanationResult.success(
            cacheResult.explanation!,
            source: 'cache',
          );
        }

        return WordExplanationResult.failure(
          'You\'re offline. Connect to the internet to look up new words.',
          errorType: AiRequestErrorType.offline,
        );
      }

      if (!await ApiConfig.isLlmConfigured) {
        return WordExplanationResult.failure(
          'Provider name or API key is missing. Add both in Settings > AI provider & key.',
          errorType: AiRequestErrorType.keyMissing,
        );
      }

      final prompt = _buildPrompt(word, bookTitle, bookAuthor);

      final generationResult = await _llmGateway.generateText(
        taskSystemPrompt: level.systemPrompt,
        userPrompt: prompt,
        maxOutputTokens: level.maxTokens,
        temperature: ApiConfig.temperature,
      );

      if (!generationResult.success || generationResult.text == null) {
        final error = generationResult.error;
        return WordExplanationResult.failure(
          error?.message ?? 'Unable to get explanation right now.',
          errorType: error?.type ?? AiRequestErrorType.unknown,
        );
      }

      final explanation = generationResult.text!.trim();
      await _cache.cacheExplanation(
        word: cacheKey,
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        explanation: explanation,
      );

      return WordExplanationResult.success(explanation, source: 'api');
    } on TimeoutException {
      return WordExplanationResult.failure(
        'Request timed out. Please check your connection and try again.',
        errorType: AiRequestErrorType.timeout,
      );
    } on FormatException {
      return WordExplanationResult.failure(
        'Failed to parse AI response. Please try again.',
        errorType: AiRequestErrorType.malformedResponse,
      );
    } on ApiKeyNotConfiguredException catch (e) {
      return WordExplanationResult.failure(
        e.message,
        errorType: AiRequestErrorType.keyMissing,
      );
    } catch (_) {
      return WordExplanationResult.failure(
        'An unexpected error occurred. Please try again.',
        errorType: AiRequestErrorType.unknown,
      );
    }
  }

  String _buildPrompt(String word, String bookTitle, String bookAuthor) {
    String prompt = 'Explain the word "$word"';

    if (bookTitle.isNotEmpty) {
      prompt += ' as it might appear in the book "$bookTitle"';
      if (bookAuthor.isNotEmpty && bookAuthor != 'Unknown Author') {
        prompt += ' by $bookAuthor';
      }
    }

    prompt += '.';
    return prompt;
  }

  Future<bool> get isConfigured async => ApiConfig.isLlmConfigured;

  void dispose() {
    _llmGateway.dispose();
  }
}
