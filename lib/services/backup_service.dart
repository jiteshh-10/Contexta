import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/backup_snapshot.dart';
import '../models/book.dart';
import '../models/word_entry.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// Handles cloud backup and restore via Firestore.
///
/// Key principles:
/// - SQLite remains the single source of truth
/// - Cloud is backup only, not live sync
/// - All operations are silent and non-blocking
/// - Debounced to avoid excessive writes
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  FirebaseFirestore? _firestore;

  // Debounce timer for backup operations
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(seconds: 3);

  // Firestore collection paths
  static const String _usersCollection = 'users';
  static const String _snapshotDocument = 'library_snapshot';

  /// Initialize Firestore instance
  void initialize(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  /// Get Firestore instance (lazy initialization)
  FirebaseFirestore get _firestoreInstance {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Schedule a backup (debounced)
  ///
  /// Call this when data changes. The actual backup will happen
  /// after [_debounceDuration] of inactivity.
  void scheduleBackup() {
    // Only backup if cloud mode is enabled
    if (!_authService.currentState.isCloudEnabled) return;

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Schedule new backup
    _debounceTimer = Timer(_debounceDuration, () {
      _performBackup();
    });
  }

  /// Perform immediate backup (for app background)
  Future<void> performImmediateBackup() async {
    _debounceTimer?.cancel();
    await _performBackup();
  }

  /// Create and upload a backup snapshot
  Future<void> _performBackup() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      _authService.setBackupInProgress(true);

      // Create snapshot from local data
      final snapshot = await _createSnapshot();

      // Upload to Firestore
      await _firestoreInstance
          .collection(_usersCollection)
          .doc(userId)
          .collection('backups')
          .doc(_snapshotDocument)
          .set(snapshot.toJson());

      // Update last backup time
      await _authService.updateLastBackupTime(DateTime.now());

      debugPrint('BackupService: Backup completed successfully');
    } catch (e) {
      debugPrint('BackupService: Backup failed: $e');
      _authService.setBackupError('Backup paused');
    }
  }

  /// Create a snapshot from local SharedPreferences data
  Future<BackupSnapshot> _createSnapshot() async {
    // Load books from SharedPreferences
    final books = await _storage.loadBooks();
    debugPrint('BackupService: Found ${books.length} books');

    // Convert books to Map format for backup
    final booksData = books.map((book) => book.toJson()).toList();

    // Collect all word entries from all books
    final List<Map<String, dynamic>> wordsData = [];
    for (final book in books) {
      for (final entry in book.words) {
        wordsData.add({
          'id': entry.id,
          'bookId': entry.bookId,
          'word': entry.word,
          'explanation': entry.explanation,
          'timestamp': entry.timestamp.toIso8601String(),
          'lookupCount': entry.lookupCount,
        });
      }
    }
    debugPrint('BackupService: Found ${wordsData.length} word entries');

    // Get preferences (subset that should be backed up)
    final preferences = await _getBackupPreferences();

    return BackupSnapshot.create(
      books: booksData,
      words: wordsData,
      quotes: [], // Not used in current app version
      readingDays: [], // Not used in current app version
      preferences: preferences,
    );
  }

  /// Get preferences that should be backed up
  Future<Map<String, dynamic>> _getBackupPreferences() async {
    // For now, we don't backup preferences (theme, etc.)
    // This can be extended in the future
    return {};
  }

  /// Check if cloud data exists for the current user
  Future<bool> hasCloudData() async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      final doc =
          await _firestoreInstance
              .collection(_usersCollection)
              .doc(userId)
              .collection('backups')
              .doc(_snapshotDocument)
              .get();

      return doc.exists;
    } catch (e) {
      debugPrint('BackupService: Error checking cloud data: $e');
      return false;
    }
  }

  /// Get cloud snapshot without restoring
  Future<BackupSnapshot?> getCloudSnapshot() async {
    final userId = _authService.currentUserId;
    if (userId == null) return null;

    try {
      final doc =
          await _firestoreInstance
              .collection(_usersCollection)
              .doc(userId)
              .collection('backups')
              .doc(_snapshotDocument)
              .get();

      if (!doc.exists || doc.data() == null) return null;

      return BackupSnapshot.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('BackupService: Error getting cloud snapshot: $e');
      return null;
    }
  }

  /// Restore data from cloud snapshot
  Future<RestoreResult> restoreFromCloud() async {
    final snapshot = await getCloudSnapshot();
    if (snapshot == null) {
      return RestoreResult.noData;
    }

    if (!snapshot.isCompatible) {
      return RestoreResult.incompatible;
    }

    try {
      await _restoreSnapshot(snapshot);
      return RestoreResult.success;
    } catch (e) {
      debugPrint('BackupService: Restore failed: $e');
      return RestoreResult.error;
    }
  }

  /// Restore data from a snapshot
  Future<void> _restoreSnapshot(BackupSnapshot snapshot) async {
    debugPrint('BackupService: Restoring ${snapshot.books.length} books...');

    // Group word entries by bookId
    final wordsByBookId = <String, List<Map<String, dynamic>>>{};
    for (final word in snapshot.words) {
      final bookId = (word['bookId'] ?? word['book_id']) as String?;
      if (bookId == null || bookId.isEmpty) continue;
      wordsByBookId.putIfAbsent(bookId, () => []);
      wordsByBookId[bookId]!.add(word);
    }

    // Convert snapshot data back to Book objects
    final books = <Book>[];
    for (final bookData in snapshot.books) {
      try {
        final bookId = bookData['id'] as String?;
        if (bookId == null || bookId.isEmpty) continue;

        final bookWords = wordsByBookId[bookId] ?? [];

        // Parse word entries for this book
        final wordEntries = <WordEntry>[];
        for (final wordData in bookWords) {
          try {
            final timestamp = wordData['timestamp'] as String?;
            wordEntries.add(
              WordEntry(
                id:
                    wordData['id'] as String? ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                word: wordData['word'] as String? ?? '',
                explanation: wordData['explanation'] as String? ?? '',
                bookId: bookId,
                timestamp:
                    timestamp != null
                        ? DateTime.tryParse(timestamp) ?? DateTime.now()
                        : DateTime.now(),
                lookupCount: wordData['lookupCount'] as int? ?? 1,
              ),
            );
          } catch (e) {
            debugPrint('BackupService: Skipping invalid word entry: $e');
          }
        }

        final createdAtStr = bookData['createdAt'] as String?;
        books.add(
          Book(
            id: bookId,
            title: bookData['title'] as String? ?? 'Unknown Title',
            author: bookData['author'] as String? ?? 'Unknown Author',
            coverUrl: bookData['coverUrl'] as String?,
            createdAt:
                createdAtStr != null
                    ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
                    : DateTime.now(),
            words: wordEntries,
          ),
        );
      } catch (e) {
        debugPrint('BackupService: Skipping invalid book: $e');
      }
    }

    // Save to SharedPreferences
    await _storage.saveBooks(books);

    debugPrint('BackupService: Restore completed - ${snapshot.summary}');
  }

  /// Check if local database is empty
  Future<bool> isLocalDatabaseEmpty() async {
    try {
      final books = await _storage.loadBooks();
      return books.isEmpty;
    } catch (e) {
      // Storage might not be initialized
      return true;
    }
  }

  /// Cancel pending backup
  void cancelPendingBackup() {
    _debounceTimer?.cancel();
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Result of a restore operation
enum RestoreResult {
  /// Restore completed successfully
  success,

  /// No cloud data found
  noData,

  /// Snapshot version incompatible
  incompatible,

  /// An error occurred during restore
  error,
}
