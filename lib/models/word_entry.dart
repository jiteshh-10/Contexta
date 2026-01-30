import 'difficulty_reason.dart';

/// WordEntry model representing a word captured while reading
/// Contains the word, its contextual explanation, and metadata
class WordEntry {
  final String id;
  final String word;
  final String explanation;
  final String bookId;
  final DateTime timestamp;
  final int lookupCount;
  final DifficultyReason? difficultyReason;
  final String? quote; // Optional: the sentence where the word appeared

  WordEntry({
    required this.id,
    required this.word,
    required this.explanation,
    required this.bookId,
    DateTime? timestamp,
    this.lookupCount = 1,
    this.difficultyReason,
    this.quote,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Check if this entry has a quote
  bool get hasQuote => quote != null && quote!.trim().isNotEmpty;

  /// Create a copy with modified fields
  WordEntry copyWith({
    String? id,
    String? word,
    String? explanation,
    String? bookId,
    DateTime? timestamp,
    int? lookupCount,
    DifficultyReason? difficultyReason,
    bool clearDifficultyReason = false,
    String? quote,
    bool clearQuote = false,
  }) {
    return WordEntry(
      id: id ?? this.id,
      word: word ?? this.word,
      explanation: explanation ?? this.explanation,
      bookId: bookId ?? this.bookId,
      timestamp: timestamp ?? this.timestamp,
      lookupCount: lookupCount ?? this.lookupCount,
      difficultyReason:
          clearDifficultyReason
              ? null
              : (difficultyReason ?? this.difficultyReason),
      quote: clearQuote ? null : (quote ?? this.quote),
    );
  }

  /// Increment lookup count
  WordEntry incrementLookup() {
    return copyWith(lookupCount: lookupCount + 1);
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
      'lookupCount': lookupCount,
      'difficultyReason': difficultyReason?.toStorageString(),
      'quote': quote,
    };
  }

  /// Create from JSON
  factory WordEntry.fromJson(Map<String, dynamic> json) {
    // Handle difficultyReason which might be null, String, or int (legacy data)
    DifficultyReason? parsedReason;
    final reasonValue = json['difficultyReason'];
    if (reasonValue is String) {
      parsedReason = DifficultyReason.fromStorageString(reasonValue);
    } else if (reasonValue is int) {
      // Handle legacy data where enum index was stored
      final values = DifficultyReason.values;
      if (reasonValue >= 0 && reasonValue < values.length) {
        parsedReason = values[reasonValue];
      }
    }
    // If null or invalid type, parsedReason stays null

    return WordEntry(
      id: json['id'] as String,
      word: json['word'] as String,
      explanation: json['explanation'] as String,
      bookId: json['bookId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      lookupCount: json['lookupCount'] as int? ?? 1,
      difficultyReason: parsedReason,
      quote: json['quote'] as String?,
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
