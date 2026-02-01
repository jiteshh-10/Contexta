import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/backup_snapshot.dart';
import '../models/book.dart';
import '../models/word_entry.dart';
import 'storage_service.dart';

/// Handles local backup file export and import.
///
/// Provides offline, account-free data ownership through
/// exportable backup files that users control.
class LocalExportService {
  static final LocalExportService _instance = LocalExportService._internal();
  factory LocalExportService() => _instance;
  LocalExportService._internal();

  final StorageService _storage = StorageService();

  // File naming
  static const String _filePrefix = 'contexta_library_';
  static const String _fileExtension = '.ctxb'; // Custom extension for branding

  /// Export library to a shareable file
  ///
  /// Returns the file path if successful, null otherwise.
  Future<ExportResult> exportLibrary() async {
    try {
      debugPrint('LocalExportService: Starting export...');

      // Create snapshot from local data
      final snapshot = await _createSnapshot();
      debugPrint('LocalExportService: Snapshot created - ${snapshot.summary}');

      if (snapshot.isEmpty) {
        debugPrint('LocalExportService: Snapshot is empty');
        return ExportResult.empty;
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filename = '$_filePrefix$timestamp$_fileExtension';

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';
      debugPrint('LocalExportService: File path - $filePath');

      // Write JSON to file
      final file = File(filePath);
      final jsonString = jsonEncode(snapshot.toJson());
      await file.writeAsString(jsonString);

      debugPrint('LocalExportService: Exported to $filePath');

      return ExportResult.success(filePath, snapshot.summary);
    } catch (e, stackTrace) {
      debugPrint('LocalExportService: Export failed: $e');
      debugPrint('LocalExportService: Stack trace: $stackTrace');
      return ExportResult.error;
    }
  }

  /// Share the exported library file
  Future<bool> shareExport(String filePath) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Contexta Library Backup',
        text: 'My Contexta reading library backup',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('LocalExportService: Share failed: $e');
      return false;
    }
  }

  /// Import library from a backup file
  ///
  /// This replaces all current local data with the backup.
  Future<ImportResult> importLibrary(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return ImportResult.fileNotFound;
      }

      // Read and parse JSON
      final jsonString = await file.readAsString();
      final Map<String, dynamic> json;

      try {
        json = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return ImportResult.invalidFormat;
      }

      // Parse snapshot
      final BackupSnapshot snapshot;
      try {
        snapshot = BackupSnapshot.fromJson(json);
      } catch (e) {
        return ImportResult.invalidFormat;
      }

      // Check compatibility
      if (!snapshot.isCompatible) {
        return ImportResult.incompatible;
      }

      // Restore the snapshot
      await _restoreSnapshot(snapshot);

      return ImportResult.success(snapshot.summary);
    } catch (e) {
      debugPrint('LocalExportService: Import failed: $e');
      return ImportResult.error;
    }
  }

  /// Create a snapshot from local SharedPreferences data
  Future<BackupSnapshot> _createSnapshot() async {
    debugPrint('LocalExportService: Loading books from StorageService...');
    final books = await _storage.loadBooks();
    debugPrint('LocalExportService: Found ${books.length} books');

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
    debugPrint('LocalExportService: Found ${wordsData.length} word entries');

    return BackupSnapshot.create(
      books: booksData,
      words: wordsData,
      quotes: [], // Not used in current app version
      readingDays: [], // Not used in current app version
      preferences: {},
    );
  }

  /// Restore data from a snapshot
  Future<void> _restoreSnapshot(BackupSnapshot snapshot) async {
    debugPrint(
      'LocalExportService: Restoring ${snapshot.books.length} books...',
    );

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
            debugPrint('LocalExportService: Skipping invalid word entry: $e');
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
        debugPrint('LocalExportService: Skipping invalid book: $e');
      }
    }

    // Save to SharedPreferences
    await _storage.saveBooks(books);

    debugPrint('LocalExportService: Restored - ${snapshot.summary}');
  }

  /// Clean up old export files
  Future<void> cleanupOldExports() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File && file.path.contains(_filePrefix)) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('LocalExportService: Cleanup failed: $e');
    }
  }
}

/// Result of an export operation
class ExportResult {
  final bool isSuccess;
  final bool isEmpty;
  final bool isError;
  final String? filePath;
  final String? summary;

  const ExportResult._({
    this.isSuccess = false,
    this.isEmpty = false,
    this.isError = false,
    this.filePath,
    this.summary,
  });

  factory ExportResult.success(String path, String summary) {
    return ExportResult._(isSuccess: true, filePath: path, summary: summary);
  }

  static const ExportResult empty = ExportResult._(isEmpty: true);
  static const ExportResult error = ExportResult._(isError: true);
}

/// Result of an import operation
class ImportResult {
  final bool isSuccess;
  final bool isFileNotFound;
  final bool isInvalidFormat;
  final bool isIncompatible;
  final bool isError;
  final String? summary;

  const ImportResult._({
    this.isSuccess = false,
    this.isFileNotFound = false,
    this.isInvalidFormat = false,
    this.isIncompatible = false,
    this.isError = false,
    this.summary,
  });

  factory ImportResult.success(String summary) {
    return ImportResult._(isSuccess: true, summary: summary);
  }

  static const ImportResult fileNotFound = ImportResult._(isFileNotFound: true);
  static const ImportResult invalidFormat = ImportResult._(
    isInvalidFormat: true,
  );
  static const ImportResult incompatible = ImportResult._(isIncompatible: true);
  static const ImportResult error = ImportResult._(isError: true);
}
