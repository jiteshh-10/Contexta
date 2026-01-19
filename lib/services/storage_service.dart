import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

/// Service for local data persistence
/// Stores books and their associated word entries
class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  // Storage keys
  static const String _booksKey = 'contexta_books';
  static const String _themeModeKey = 'contexta_theme_mode';
  static const String _firstLaunchKey = 'contexta_first_launch';

  /// Initialize the storage service
  /// Must be called before using any other methods
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure prefs is initialized
  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StateError(
        'StorageService not initialized. Call initialize() first.',
      );
    }
    return _prefs!;
  }

  // ============ Books Storage ============

  /// Save all books to local storage
  Future<bool> saveBooks(List<Book> books) async {
    try {
      final booksJson = books.map((book) => book.toJson()).toList();
      final encoded = jsonEncode(booksJson);
      return await _preferences.setString(_booksKey, encoded);
    } catch (e) {
      // Error handling - fails silently in production
      return false;
    }
  }

  /// Load all books from local storage
  Future<List<Book>> loadBooks() async {
    try {
      final encoded = _preferences.getString(_booksKey);
      if (encoded == null || encoded.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map((json) => Book.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Error handling - returns empty list on failure
      return [];
    }
  }

  /// Add a single book and persist
  Future<bool> addBook(Book book, List<Book> currentBooks) async {
    final updatedBooks = [book, ...currentBooks];
    return saveBooks(updatedBooks);
  }

  /// Remove a book and persist
  Future<bool> removeBook(String bookId, List<Book> currentBooks) async {
    final updatedBooks = currentBooks.where((b) => b.id != bookId).toList();
    return saveBooks(updatedBooks);
  }

  /// Update a book and persist
  Future<bool> updateBook(Book book, List<Book> currentBooks) async {
    final updatedBooks =
        currentBooks.map((b) {
          return b.id == book.id ? book : b;
        }).toList();
    return saveBooks(updatedBooks);
  }

  /// Clear all books
  Future<bool> clearBooks() async {
    return await _preferences.remove(_booksKey);
  }

  // ============ Theme Storage ============

  /// Save theme mode preference
  /// Returns: 'light', 'dark', or 'system'
  Future<bool> saveThemeMode(String mode) async {
    return await _preferences.setString(_themeModeKey, mode);
  }

  /// Load theme mode preference
  String? loadThemeMode() {
    return _preferences.getString(_themeModeKey);
  }

  // ============ First Launch ============

  /// Check if this is the first launch
  bool get isFirstLaunch {
    return _preferences.getBool(_firstLaunchKey) ?? true;
  }

  /// Mark app as launched (no longer first launch)
  Future<bool> markAsLaunched() async {
    return await _preferences.setBool(_firstLaunchKey, false);
  }

  // ============ Utility Methods ============

  /// Get storage stats
  Map<String, dynamic> getStats() {
    final booksData = _preferences.getString(_booksKey);
    return {
      'booksDataSize': booksData?.length ?? 0,
      'hasBooks': booksData != null && booksData.isNotEmpty,
      'isFirstLaunch': isFirstLaunch,
      'themeMode': loadThemeMode(),
    };
  }

  /// Clear all stored data
  Future<bool> clearAll() async {
    return await _preferences.clear();
  }
}
