import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/explanation_level.dart';
import 'word_explanation_cache_service.dart';
import 'connectivity_service.dart';

/// Result class for word explanation API calls
class WordExplanationResult {
  final bool success;
  final String? explanation;
  final String? error;
  final String source; // 'cache', 'api', or 'error'

  const WordExplanationResult._({
    required this.success,
    this.explanation,
    this.error,
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

  factory WordExplanationResult.failure(String error) {
    return WordExplanationResult._(
      success: false,
      error: error,
      source: 'error',
    );
  }

  /// Check if result came from cache
  bool get isFromCache => source == 'cache';
}

/// Service for interacting with Perplexity API
/// Provides contextual word explanations based on book context
///
/// Features:
/// - Offline-first: Checks cache before making API calls
/// - Automatic caching of API responses
/// - Connectivity-aware: Returns cached results when offline
class PerplexityService {
  // Singleton pattern
  static final PerplexityService _instance = PerplexityService._internal();
  factory PerplexityService() => _instance;
  PerplexityService._internal();

  final http.Client _client = http.Client();
  final WordExplanationCacheService _cache = WordExplanationCacheService();
  final ConnectivityService _connectivity = ConnectivityService();

  /// Get explanation for a word in the context of a specific book
  ///
  /// [word] - The word to explain
  /// [bookTitle] - The title of the book for context
  /// [bookAuthor] - The author of the book for additional context
  /// [level] - The explanation depth level (Simple, Literary, Deep)
  /// [forceRefresh] - Skip cache and fetch fresh from API
  Future<WordExplanationResult> explainWord({
    required String word,
    required String bookTitle,
    required String bookAuthor,
    ExplanationLevel level = ExplanationLevel.simple,
    bool forceRefresh = false,
  }) async {
    try {
      // Generate cache key that includes the level
      final cacheKey = '${word.toLowerCase()}_${level.name}';

      // Step 1: Check cache first (unless force refresh)
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

      // Step 2: Check connectivity
      final isOnline = _connectivity.isOnline;
      if (!isOnline) {
        // Try cache one more time in case forceRefresh was true
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
        );
      }

      // Step 3: Check if API key is configured
      if (!ApiConfig.isApiKeyConfigured) {
        return WordExplanationResult.failure(
          'API key not configured. Please add your Perplexity API key to the .env file.',
        );
      }

      // Step 4: Make API call
      final apiKey = ApiConfig.perplexityApiKey;
      final url = Uri.parse(
        '${ApiConfig.perplexityBaseUrl}${ApiConfig.chatCompletionsEndpoint}',
      );

      // Build the prompt for contextual explanation
      final prompt = _buildPrompt(word, bookTitle, bookAuthor);

      final requestBody = jsonEncode({
        'model': ApiConfig.perplexityModel,
        'messages': [
          {'role': 'system', 'content': level.systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': level.maxTokens,
        'temperature': ApiConfig.temperature,
      });

      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: requestBody,
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          final explanation = content.trim();

          // Step 5: Cache the successful response for offline access
          await _cache.cacheExplanation(
            word: cacheKey,
            bookTitle: bookTitle,
            bookAuthor: bookAuthor,
            explanation: explanation,
          );

          return WordExplanationResult.success(explanation, source: 'api');
        } else {
          return WordExplanationResult.failure(
            'Received empty response from API.',
          );
        }
      } else if (response.statusCode == 401) {
        return WordExplanationResult.failure(
          'Invalid API key. Please check your Perplexity API key.',
        );
      } else if (response.statusCode == 429) {
        return WordExplanationResult.failure(
          'Rate limit exceeded. Please try again in a moment.',
        );
      } else if (response.statusCode >= 500) {
        return WordExplanationResult.failure(
          'Perplexity service is temporarily unavailable. Please try again later.',
        );
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        return WordExplanationResult.failure('API error: $errorMessage');
      }
    } on TimeoutException {
      return WordExplanationResult.failure(
        'Request timed out. Please check your connection and try again.',
      );
    } on http.ClientException catch (e) {
      return WordExplanationResult.failure('Network error: ${e.message}');
    } on FormatException {
      return WordExplanationResult.failure('Failed to parse API response.');
    } on ApiKeyNotConfiguredException catch (e) {
      return WordExplanationResult.failure(e.message);
    } catch (e) {
      return WordExplanationResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Build the prompt for word explanation
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

  /// Check if the service is properly configured
  bool get isConfigured => ApiConfig.isApiKeyConfigured;

  /// Dispose of resources
  void dispose() {
    _client.close();
  }
}
