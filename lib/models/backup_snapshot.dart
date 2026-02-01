/// A complete snapshot of the user's library for backup/restore.
///
/// Contains all user data in a serializable format.
/// Used for both cloud backup (Firestore) and local export.
class BackupSnapshot {
  final String version;
  final DateTime createdAt;
  final List<Map<String, dynamic>> books;
  final List<Map<String, dynamic>> words;
  final List<Map<String, dynamic>> quotes;
  final List<Map<String, dynamic>> readingDays;
  final Map<String, dynamic> preferences;

  /// Current schema version for migration compatibility
  static const String currentVersion = '1.0.0';

  BackupSnapshot({
    required this.version,
    required this.createdAt,
    required this.books,
    required this.words,
    required this.quotes,
    required this.readingDays,
    required this.preferences,
  });

  /// Create a new snapshot with current data
  factory BackupSnapshot.create({
    required List<Map<String, dynamic>> books,
    required List<Map<String, dynamic>> words,
    required List<Map<String, dynamic>> quotes,
    required List<Map<String, dynamic>> readingDays,
    required Map<String, dynamic> preferences,
  }) {
    return BackupSnapshot(
      version: currentVersion,
      createdAt: DateTime.now(),
      books: books,
      words: words,
      quotes: quotes,
      readingDays: readingDays,
      preferences: preferences,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'books': books,
      'words': words,
      'quotes': quotes,
      'readingDays': readingDays,
      'preferences': preferences,
    };
  }

  /// Parse from JSON
  factory BackupSnapshot.fromJson(Map<String, dynamic> json) {
    return BackupSnapshot(
      version: json['version'] as String? ?? '1.0.0',
      createdAt: DateTime.parse(json['createdAt'] as String),
      books: List<Map<String, dynamic>>.from(
        (json['books'] as List).map((e) => Map<String, dynamic>.from(e)),
      ),
      words: List<Map<String, dynamic>>.from(
        (json['words'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
      quotes: List<Map<String, dynamic>>.from(
        (json['quotes'] as List? ?? []).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      ),
      readingDays: List<Map<String, dynamic>>.from(
        (json['readingDays'] as List? ?? []).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      ),
      preferences: Map<String, dynamic>.from(json['preferences'] as Map? ?? {}),
    );
  }

  /// Check if this snapshot is compatible with current app version
  bool get isCompatible {
    // For now, all 1.x.x versions are compatible
    final parts = version.split('.');
    if (parts.isEmpty) return false;
    final major = int.tryParse(parts[0]);
    return major == 1;
  }

  /// Get a human-readable summary of the snapshot
  String get summary {
    final bookCount = books.length;
    final wordCount = words.length;
    final quoteCount = quotes.length;

    final parts = <String>[];
    if (bookCount > 0) parts.add('$bookCount book${bookCount == 1 ? '' : 's'}');
    if (wordCount > 0) parts.add('$wordCount word${wordCount == 1 ? '' : 's'}');
    if (quoteCount > 0) {
      parts.add('$quoteCount quote${quoteCount == 1 ? '' : 's'}');
    }

    if (parts.isEmpty) return 'Empty library';
    return parts.join(', ');
  }

  /// Check if the snapshot has any data
  bool get isEmpty => books.isEmpty && words.isEmpty && quotes.isEmpty;

  /// Check if the snapshot has data
  bool get hasData => !isEmpty;
}
