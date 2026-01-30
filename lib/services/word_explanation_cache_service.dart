import 'package:flutter/foundation.dart';
import 'database/database_service.dart';

/// Result class for cache operations
class CacheResult {
  final bool hit;
  final String? explanation;
  final String? source;

  const CacheResult._({required this.hit, this.explanation, this.source});

  factory CacheResult.hit(String explanation) {
    return CacheResult._(hit: true, explanation: explanation, source: 'cache');
  }

  factory CacheResult.miss() {
    return const CacheResult._(hit: false);
  }
}

/// Service for caching word explanations locally
///
/// Features:
/// - Offline-first word explanation retrieval
/// - LRU-based cache eviction
/// - Configurable cache expiry
/// - Cache statistics and management
class WordExplanationCacheService {
  // Singleton pattern
  static final WordExplanationCacheService _instance =
      WordExplanationCacheService._internal();
  factory WordExplanationCacheService() => _instance;
  WordExplanationCacheService._internal();

  final DatabaseService _db = DatabaseService();

  // Cache configuration
  static const int maxCacheSize = 10000; // Maximum cached entries
  static const Duration defaultCacheDuration = Duration(
    days: 365,
  ); // Cache for 1 year by default

  /// Get cached explanation for a word
  ///
  /// Returns [CacheResult.hit] if found, [CacheResult.miss] otherwise
  Future<CacheResult> getExplanation({
    required String word,
    required String bookTitle,
    required String bookAuthor,
  }) async {
    try {
      final normalizedWord = _normalizeWord(word);
      final normalizedTitle = _normalizeText(bookTitle);
      final normalizedAuthor = _normalizeText(bookAuthor);

      final results = await _db.query(
        'word_explanation_cache',
        columns: ['id', 'explanation', 'expires_at'],
        where: 'word = ? AND book_title = ? AND book_author = ?',
        whereArgs: [normalizedWord, normalizedTitle, normalizedAuthor],
        limit: 1,
      );

      if (results.isEmpty) {
        debugPrint('WordExplanationCache: MISS for "$word"');
        return CacheResult.miss();
      }

      final row = results.first;
      final expiresAt = row['expires_at'] as String?;

      // Check if cache entry has expired
      if (expiresAt != null) {
        final expiryDate = DateTime.parse(expiresAt);
        if (DateTime.now().isAfter(expiryDate)) {
          debugPrint('WordExplanationCache: EXPIRED for "$word"');
          // Clean up expired entry
          await _db.delete(
            'word_explanation_cache',
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          return CacheResult.miss();
        }
      }

      // Update access stats
      await _updateAccessStats(row['id'] as int);

      debugPrint('WordExplanationCache: HIT for "$word"');
      return CacheResult.hit(row['explanation'] as String);
    } catch (e) {
      debugPrint('WordExplanationCache: Error getting explanation: $e');
      return CacheResult.miss();
    }
  }

  /// Store explanation in cache
  Future<bool> cacheExplanation({
    required String word,
    required String bookTitle,
    required String bookAuthor,
    required String explanation,
    Duration? cacheDuration,
  }) async {
    try {
      final normalizedWord = _normalizeWord(word);
      final normalizedTitle = _normalizeText(bookTitle);
      final normalizedAuthor = _normalizeText(bookAuthor);

      final now = DateTime.now();
      final expiresAt = now.add(cacheDuration ?? defaultCacheDuration);

      // Use INSERT OR REPLACE to handle duplicates
      await _db.insert('word_explanation_cache', {
        'word': normalizedWord,
        'book_title': normalizedTitle,
        'book_author': normalizedAuthor,
        'explanation': explanation,
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'hit_count': 0,
        'last_accessed_at': now.toIso8601String(),
        'metadata': '{}',
      });

      debugPrint('WordExplanationCache: Cached "$word"');

      // Trigger cache cleanup if needed
      await _cleanupIfNeeded();

      return true;
    } catch (e) {
      debugPrint('WordExplanationCache: Error caching explanation: $e');
      return false;
    }
  }

  /// Update access statistics for cache analytics
  Future<void> _updateAccessStats(int id) async {
    try {
      await _db.rawExecute(
        '''
        UPDATE word_explanation_cache 
        SET hit_count = hit_count + 1, 
            last_accessed_at = ? 
        WHERE id = ?
        ''',
        [DateTime.now().toIso8601String(), id],
      );
    } catch (e) {
      // Non-critical, don't throw
      debugPrint('WordExplanationCache: Error updating stats: $e');
    }
  }

  /// Cleanup cache if it exceeds max size using LRU eviction
  Future<void> _cleanupIfNeeded() async {
    try {
      final countResult = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM word_explanation_cache',
      );
      final count = countResult.first['count'] as int;

      if (count > maxCacheSize) {
        final toDelete =
            count - maxCacheSize + (maxCacheSize ~/ 10); // Delete 10% extra

        // Delete least recently used entries
        await _db.rawExecute(
          '''
          DELETE FROM word_explanation_cache 
          WHERE id IN (
            SELECT id FROM word_explanation_cache 
            ORDER BY last_accessed_at ASC 
            LIMIT ?
          )
          ''',
          [toDelete],
        );

        debugPrint('WordExplanationCache: Cleaned up $toDelete entries');
      }
    } catch (e) {
      debugPrint('WordExplanationCache: Error during cleanup: $e');
    }
  }

  /// Clear all expired cache entries
  Future<int> clearExpired() async {
    try {
      final now = DateTime.now().toIso8601String();
      final deleted = await _db.delete(
        'word_explanation_cache',
        where: 'expires_at IS NOT NULL AND expires_at < ?',
        whereArgs: [now],
      );
      debugPrint('WordExplanationCache: Cleared $deleted expired entries');
      return deleted;
    } catch (e) {
      debugPrint('WordExplanationCache: Error clearing expired: $e');
      return 0;
    }
  }

  /// Clear all cached explanations
  Future<void> clearAll() async {
    try {
      await _db.delete('word_explanation_cache');
      debugPrint('WordExplanationCache: Cleared all cache');
    } catch (e) {
      debugPrint('WordExplanationCache: Error clearing cache: $e');
    }
  }

  /// Clear cache for a specific book
  Future<void> clearForBook(String bookTitle, String bookAuthor) async {
    try {
      await _db.delete(
        'word_explanation_cache',
        where: 'book_title = ? AND book_author = ?',
        whereArgs: [_normalizeText(bookTitle), _normalizeText(bookAuthor)],
      );
      debugPrint('WordExplanationCache: Cleared cache for book "$bookTitle"');
    } catch (e) {
      debugPrint('WordExplanationCache: Error clearing book cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final countResult = await _db.rawQuery(
        'SELECT COUNT(*) as total FROM word_explanation_cache',
      );
      final totalHitsResult = await _db.rawQuery(
        'SELECT SUM(hit_count) as total_hits FROM word_explanation_cache',
      );
      final oldestResult = await _db.rawQuery(
        'SELECT MIN(created_at) as oldest FROM word_explanation_cache',
      );
      final newestResult = await _db.rawQuery(
        'SELECT MAX(created_at) as newest FROM word_explanation_cache',
      );

      return {
        'totalEntries': countResult.first['total'] ?? 0,
        'totalHits': totalHitsResult.first['total_hits'] ?? 0,
        'oldestEntry': oldestResult.first['oldest'],
        'newestEntry': newestResult.first['newest'],
        'maxSize': maxCacheSize,
      };
    } catch (e) {
      debugPrint('WordExplanationCache: Error getting stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Normalize word for consistent cache keys
  String _normalizeWord(String word) {
    return word.trim().toLowerCase();
  }

  /// Normalize text for consistent cache keys
  String _normalizeText(String text) {
    return text.trim().toLowerCase();
  }

  /// Preload explanations for a list of words (for offline preparation)
  Future<Map<String, String>> preloadExplanations({
    required List<String> words,
    required String bookTitle,
    required String bookAuthor,
  }) async {
    final Map<String, String> cached = {};

    for (final word in words) {
      final result = await getExplanation(
        word: word,
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
      );

      if (result.hit && result.explanation != null) {
        cached[word] = result.explanation!;
      }
    }

    return cached;
  }
}
