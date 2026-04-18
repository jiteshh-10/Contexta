import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/ai_request_error.dart';
import '../models/book.dart';
import '../models/book_suggestion.dart';
import 'connectivity_service.dart';
import 'llm_gateway_service.dart';

/// Result class for book suggestion API calls
class BookSuggestionsResult {
  final bool success;
  final List<BookSuggestion> suggestions;
  final String? error;
  final AiRequestErrorType errorType;
  final String source; // 'cache', 'api', or 'error'

  const BookSuggestionsResult._({
    required this.success,
    this.suggestions = const [],
    this.error,
    this.errorType = AiRequestErrorType.none,
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

  factory BookSuggestionsResult.failure(
    String error, {
    AiRequestErrorType errorType = AiRequestErrorType.unknown,
  }) {
    return BookSuggestionsResult._(
      success: false,
      error: error,
      errorType: errorType,
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

  final LlmGatewayService _llmGateway = LlmGatewayService();
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
          errorType: AiRequestErrorType.offline,
        );
      }

      // Step 3: Check API key
      if (!await ApiConfig.isLlmConfigured) {
        return BookSuggestionsResult.failure(
          'Provider name or API key is missing. Add both in Settings > AI provider & key.',
          errorType: AiRequestErrorType.keyMissing,
        );
      }

      // Step 4: Build context from reading history
      final context = _buildReadingContext(books);

      // Step 5: Make API call

      final systemPrompt =
          '''You are a thoughtful librarian helping a reader discover their next book.

Based on the reader's COMPLETE library (analyze ALL books listed, not just one), suggest exactly 3 books they might enjoy.

IMPORTANT RULES:
1. Never suggest books already in their library
2. Consider the ENTIRE library - look for patterns across ALL books
3. Each suggestion must include a clear, personal reason
4. Reasons should reference their reading patterns, themes, or author preferences
5. Use phrases like "You might enjoy...", "Similar in tone to...", "Often read after...", "Given your interest in..."
6. Never use terms like "recommended", "top pick", "trending", "AI-powered"
7. Keep reasons to one thoughtful sentence
8. Focus on literary merit and thematic connections across their whole collection
9. Suggest DIFFERENT books each time - vary your recommendations

Respond ONLY with valid JSON in this exact format:
{
  "suggestions": [
    {"title": "Book Title", "author": "Author Name", "reason": "One sentence explaining why based on their reading"},
    {"title": "Book Title", "author": "Author Name", "reason": "One sentence explaining why"},
    {"title": "Book Title", "author": "Author Name", "reason": "One sentence explaining why"}
  ]
}''';

      final userPrompt =
          '''Based on this reader's COMPLETE library, suggest 3 thoughtful book recommendations:

$context

Remember: 
- Analyze ALL books in their library, not just the first one
- Don't suggest any books already listed above
- Each reason should feel personal and reference their reading patterns
- Sound like a librarian, not an algorithm
- These should be FRESH suggestions different from previous ones''';

      final generationResult = await _llmGateway.generateText(
        taskSystemPrompt: systemPrompt,
        userPrompt: userPrompt,
        maxOutputTokens: 700,
        temperature: forceRefresh ? 0.9 : 0.7,
      );

      if (!generationResult.success || generationResult.text == null) {
        final error = generationResult.error;
        return BookSuggestionsResult.failure(
          error?.message ?? 'Unable to get suggestions right now.',
          errorType: error?.type ?? AiRequestErrorType.unknown,
        );
      }

      final suggestions = _parseResponse(generationResult.text!, books);
      if (suggestions.isEmpty) {
        return BookSuggestionsResult.failure(
          'Received invalid suggestion format from the provider. Please try again.',
          errorType: AiRequestErrorType.malformedResponse,
        );
      }

      // Cache the suggestions
      await _cacheSuggestions(suggestions, books);

      return BookSuggestionsResult.success(suggestions, source: 'api');
    } on TimeoutException {
      return BookSuggestionsResult.failure(
        'Request timed out. Please try again.',
        errorType: AiRequestErrorType.timeout,
      );
    } on FormatException {
      return BookSuggestionsResult.failure(
        'Failed to parse AI response. Please try again.',
        errorType: AiRequestErrorType.malformedResponse,
      );
    } on ApiKeyNotConfiguredException catch (e) {
      return BookSuggestionsResult.failure(
        e.message,
        errorType: AiRequestErrorType.keyMissing,
      );
    } catch (_) {
      return BookSuggestionsResult.failure(
        'Something went wrong. Please try again.',
        errorType: AiRequestErrorType.unknown,
      );
    }
  }

  /// Build reading context from books
  String _buildReadingContext(List<Book> books) {
    final buffer = StringBuffer();
    buffer.writeln('READER\'S COMPLETE LIBRARY (${books.length} books):');
    buffer.writeln('');

    // List all books with their authors
    for (var i = 0; i < books.length; i++) {
      final book = books[i];
      buffer.writeln('${i + 1}. "${book.title}" by ${book.author}');

      // Add word themes if available (limited to show patterns)
      if (book.words.isNotEmpty) {
        final words = book.words.take(5).map((w) => w.word).join(', ');
        buffer.writeln('   Words explored: $words');
      }
    }

    buffer.writeln('');
    buffer.writeln('READING PATTERNS:');

    // Author analysis
    final authorCounts = <String, int>{};
    for (final book in books) {
      authorCounts[book.author] = (authorCounts[book.author] ?? 0) + 1;
    }

    final favoriteAuthors =
        authorCounts.entries
            .where((e) => e.value > 1)
            .map((e) => '${e.key} (${e.value} books)')
            .toList();

    if (favoriteAuthors.isNotEmpty) {
      buffer.writeln('- Favorite authors: ${favoriteAuthors.join(', ')}');
    }

    // Word exploration level
    final totalWords = books.fold(0, (sum, b) => sum + b.wordCount);
    if (totalWords > 50) {
      buffer.writeln(
        '- Very active vocabulary explorer ($totalWords words saved)',
      );
    } else if (totalWords > 20) {
      buffer.writeln('- Active vocabulary explorer ($totalWords words saved)');
    } else if (totalWords > 0) {
      buffer.writeln('- Casual vocabulary explorer ($totalWords words saved)');
    }

    // Recent additions (last 3)
    if (books.length > 3) {
      final recent = books.take(3).map((b) => '"${b.title}"').join(', ');
      buffer.writeln('- Recently added: $recent');
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
    _llmGateway.dispose();
  }
}
