import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/book.dart';
import '../models/book_suggestion.dart';
import 'connectivity_service.dart';

/// Result class for book suggestion API calls
class BookSuggestionsResult {
  final bool success;
  final List<BookSuggestion> suggestions;
  final String? error;
  final String source; // 'cache', 'api', or 'error'

  const BookSuggestionsResult._({
    required this.success,
    this.suggestions = const [],
    this.error,
    this.source = 'api',
  });

  factory BookSuggestionsResult.success(
    List<BookSuggestion> suggestions, {
    String source = 'api',
  }) {
    return BookSuggestionsResult._(
      success: true,
      suggestions: suggestions,
      source: source,
    );
  }

  factory BookSuggestionsResult.failure(String error) {
    return BookSuggestionsResult._(
      success: false,
      error: error,
      source: 'error',
    );
  }

  /// Check if result came from cache
  bool get isFromCache => source == 'cache';
}

/// Service for generating thoughtful book suggestions
///
/// Philosophy:
/// - Suggest like a librarian, not an algorithm
/// - Max 3 suggestions with clear reasoning
/// - User-initiated only, never push
/// - Respect reading history, don't demand preferences
class BookSuggestionService {
  // Singleton pattern
  static final BookSuggestionService _instance =
      BookSuggestionService._internal();
  factory BookSuggestionService() => _instance;
  BookSuggestionService._internal();

  final http.Client _client = http.Client();
  final ConnectivityService _connectivity = ConnectivityService();

  // Cache key for suggestions
  static const String _cacheKey = 'contexta_book_suggestions';
  static const String _cacheTimestampKey = 'contexta_suggestions_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Generate book suggestions based on reading history
  ///
  /// [books] - Current books on the shelf
  /// [forceRefresh] - Skip cache and fetch fresh from API
  ///
  /// Returns max 3 suggestions with reasoning
  Future<BookSuggestionsResult> getSuggestions({
    required List<Book> books,
    bool forceRefresh = false,
  }) async {
    try {
      // No books = no personalized suggestions
      if (books.isEmpty) {
        return BookSuggestionsResult.success([]);
      }

      // Step 1: Check cache (unless force refresh)
      if (!forceRefresh) {
        final cached = await _getCachedSuggestions(books);
        if (cached != null) {
          return BookSuggestionsResult.success(cached, source: 'cache');
        }
      }

      // Step 2: Check connectivity
      final isOnline = _connectivity.isOnline;
      if (!isOnline) {
        // Try cache anyway
        final cached = await _getCachedSuggestions(books);
        if (cached != null) {
          return BookSuggestionsResult.success(cached, source: 'cache');
        }

        return BookSuggestionsResult.failure(
          'You\'re offline. Connect to the internet to get reading suggestions.',
        );
      }

      // Step 3: Check API key
      if (!ApiConfig.isApiKeyConfigured) {
        return BookSuggestionsResult.failure('API key not configured.');
      }

      // Step 4: Build context from reading history
      final context = _buildReadingContext(books);

      // Step 5: Make API call
      final apiKey = ApiConfig.perplexityApiKey;
      final url = Uri.parse(
        '${ApiConfig.perplexityBaseUrl}${ApiConfig.chatCompletionsEndpoint}',
      );

      final systemPrompt =
          '''You are a thoughtful librarian helping a reader discover their next book.

Based on the reader's library, suggest exactly 3 books they might enjoy.

IMPORTANT RULES:
1. Never suggest books already in their library
2. Each suggestion must include a clear, personal reason
3. Reasons should reference their reading patterns or themes
4. Use phrases like "You might enjoy...", "Similar in tone to...", "Often read after..."
5. Never use terms like "recommended", "top pick", "trending", "AI-powered"
6. Keep reasons to one thoughtful sentence
7. Focus on literary merit and thematic connections

Respond ONLY with valid JSON in this exact format:
{
  "suggestions": [
    {"title": "Book Title", "author": "Author Name", "reason": "One sentence explaining why based on their reading"},
    {"title": "Book Title", "author": "Author Name", "reason": "One sentence explaining why"},
    {"title": "Book Title", "author": "Author Name", "reason": "One sentence explaining why"}
  ]
}''';

      final userPrompt =
          '''Based on this reader's library, suggest 3 thoughtful book recommendations:

$context

Remember: 
- Don't suggest any books already listed above
- Each reason should feel personal and reference their reading
- Sound like a librarian, not an algorithm''';

      final requestBody = jsonEncode({
        'model': ApiConfig.perplexityModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'max_tokens': 500,
        'temperature': 0.7,
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
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          final suggestions = _parseResponse(content, books);

          // Cache the suggestions
          await _cacheSuggestions(suggestions, books);

          return BookSuggestionsResult.success(suggestions, source: 'api');
        }

        return BookSuggestionsResult.failure(
          'Received empty response from API.',
        );
      } else if (response.statusCode == 401) {
        return BookSuggestionsResult.failure('Invalid API key.');
      } else if (response.statusCode == 429) {
        return BookSuggestionsResult.failure('Please try again in a moment.');
      } else {
        return BookSuggestionsResult.failure(
          'Unable to get suggestions right now.',
        );
      }
    } on TimeoutException {
      return BookSuggestionsResult.failure(
        'Request timed out. Please try again.',
      );
    } on http.ClientException {
      return BookSuggestionsResult.failure(
        'Network error. Please check your connection.',
      );
    } catch (e) {
      return BookSuggestionsResult.failure(
        'Something went wrong. Please try again.',
      );
    }
  }

  /// Build reading context from books
  String _buildReadingContext(List<Book> books) {
    final buffer = StringBuffer();
    buffer.writeln('READER\'S LIBRARY:');

    for (final book in books) {
      buffer.writeln('- "${book.title}" by ${book.author}');

      // Add word themes if available (limited to show patterns)
      if (book.words.isNotEmpty) {
        final words = book.words.take(5).map((w) => w.word).join(', ');
        buffer.writeln('  (Words explored: $words)');
      }
    }

    // Add some reading pattern insights
    final authors = books.map((b) => b.author).toSet();
    if (authors.length < books.length) {
      buffer.writeln('\nNote: Reader has multiple books by the same author.');
    }

    final totalWords = books.fold(0, (sum, b) => sum + b.wordCount);
    if (totalWords > 20) {
      buffer.writeln('Note: Reader actively explores vocabulary.');
    }

    return buffer.toString();
  }

  /// Parse API response into suggestions
  List<BookSuggestion> _parseResponse(String content, List<Book> books) {
    try {
      // Extract JSON from response (handle markdown code blocks)
      String jsonStr = content.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final suggestionsJson = data['suggestions'] as List<dynamic>?;

      if (suggestionsJson == null || suggestionsJson.isEmpty) {
        return [];
      }

      final suggestions = <BookSuggestion>[];
      for (final item in suggestionsJson) {
        if (item is Map<String, dynamic>) {
          final suggestion = BookSuggestion.fromJson(item);

          // Filter out books already on shelf
          final isOnShelf = books.any(
            (b) => suggestion.matchesBook(b.title, b.author),
          );

          if (!isOnShelf && suggestion.title.isNotEmpty) {
            suggestions.add(suggestion);
          }
        }
      }

      // Return max 3 suggestions
      return suggestions.take(3).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get cached suggestions if valid
  Future<List<BookSuggestion>?> _getCachedSuggestions(List<Book> books) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists and is not expired
      final timestampStr = prefs.getString(_cacheTimestampKey);
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        return null;
      }

      // Check if library has changed (simple hash check)
      final currentHash = _libraryHash(books);
      final cachedHash = prefs.getString('${_cacheKey}_hash');
      if (cachedHash != currentHash) {
        return null; // Library changed, need fresh suggestions
      }

      // Load cached suggestions
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as List<dynamic>;
      final suggestions =
          data
              .map(
                (item) => BookSuggestion.fromJson(item as Map<String, dynamic>),
              )
              .toList();

      // Filter out any that are now on shelf
      return suggestions
          .where((s) => !books.any((b) => s.matchesBook(b.title, b.author)))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Cache suggestions for later
  Future<void> _cacheSuggestions(
    List<BookSuggestion> suggestions,
    List<Book> books,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _cacheKey,
        jsonEncode(suggestions.map((s) => s.toJson()).toList()),
      );
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
      await prefs.setString('${_cacheKey}_hash', _libraryHash(books));
    } catch (e) {
      // Silently fail cache writes
    }
  }

  /// Generate a simple hash of the library for change detection
  String _libraryHash(List<Book> books) {
    final titles = books.map((b) => '${b.title}|${b.author}').join(',');
    return titles.hashCode.toString();
  }

  /// Clear cached suggestions (e.g., when user dismisses all)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove('${_cacheKey}_hash');
    } catch (e) {
      // Silently fail
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
