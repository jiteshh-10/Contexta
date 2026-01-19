import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Result class for word explanation API calls
class WordExplanationResult {
  final bool success;
  final String? explanation;
  final String? error;

  const WordExplanationResult._({
    required this.success,
    this.explanation,
    this.error,
  });

  factory WordExplanationResult.success(String explanation) {
    return WordExplanationResult._(success: true, explanation: explanation);
  }

  factory WordExplanationResult.failure(String error) {
    return WordExplanationResult._(success: false, error: error);
  }
}

/// Service for interacting with Perplexity API
/// Provides contextual word explanations based on book context
class PerplexityService {
  // Singleton pattern
  static final PerplexityService _instance = PerplexityService._internal();
  factory PerplexityService() => _instance;
  PerplexityService._internal();

  final http.Client _client = http.Client();

  /// Get explanation for a word in the context of a specific book
  ///
  /// [word] - The word to explain
  /// [bookTitle] - The title of the book for context
  /// [bookAuthor] - The author of the book for additional context
  Future<WordExplanationResult> explainWord({
    required String word,
    required String bookTitle,
    required String bookAuthor,
  }) async {
    try {
      // Check if API key is configured
      if (!ApiConfig.isApiKeyConfigured) {
        return WordExplanationResult.failure(
          'API key not configured. Please add your Perplexity API key to the .env file.',
        );
      }

      final apiKey = ApiConfig.perplexityApiKey;
      final url = Uri.parse(
        '${ApiConfig.perplexityBaseUrl}${ApiConfig.chatCompletionsEndpoint}',
      );

      // Build the prompt for contextual explanation
      final prompt = _buildPrompt(word, bookTitle, bookAuthor);

      final requestBody = jsonEncode({
        'model': ApiConfig.perplexityModel,
        'messages': [
          {
            'role': 'system',
            'content':
                '''You are a literary companion helping readers understand unfamiliar words encountered while reading.

Provide your response in EXACTLY this format (use the separator line exactly as shown):

[4-5 word short definition in plain text]
---
[Detailed contextual explanation in 2-3 sentences explaining the word's significance in the context of the book or literary genre, using sophisticated but accessible language in flowing prose.]

IMPORTANT: Do NOT use any markdown formatting like asterisks, bold, or italics. Write everything in plain text only.

Example:

Lasting only a brief moment
---
In the context of this novel, "ephemeral" captures the fleeting nature of human connections and memories that the author weaves throughout the narrative. It emphasizes how precious moments become precisely because they cannot last forever.''',
          },
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': ApiConfig.maxTokens,
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
          return WordExplanationResult.success(content.trim());
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
