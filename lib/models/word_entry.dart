/// WordEntry model representing a word captured while reading
/// Contains the word, its contextual explanation, and metadata
class WordEntry {
  final String id;
  final String word;
  final String explanation;
  final String bookId;
  final DateTime timestamp;

  WordEntry({
    required this.id,
    required this.word,
    required this.explanation,
    required this.bookId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a copy with modified fields
  WordEntry copyWith({
    String? id,
    String? word,
    String? explanation,
    String? bookId,
    DateTime? timestamp,
  }) {
    return WordEntry(
      id: id ?? this.id,
      word: word ?? this.word,
      explanation: explanation ?? this.explanation,
      bookId: bookId ?? this.bookId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Format timestamp as relative time
  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Format timestamp as full date
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  /// Get the capitalized word
  String get capitalizedWord {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'explanation': explanation,
      'bookId': bookId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      id: json['id'] as String,
      word: json['word'] as String,
      explanation: json['explanation'] as String,
      bookId: json['bookId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WordEntry(id: $id, word: $word, bookId: $bookId)';
}
