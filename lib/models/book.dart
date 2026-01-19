import 'word_entry.dart';

/// Book model representing a book in the user's library
/// Contains metadata and associated word entries
class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final DateTime createdAt;
  final List<WordEntry> words;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    DateTime? createdAt,
    List<WordEntry>? words,
  }) : createdAt = createdAt ?? DateTime.now(),
       words = words ?? [];

  /// Create a copy with modified fields
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    DateTime? createdAt,
    List<WordEntry>? words,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
      words: words ?? this.words,
    );
  }

  /// Add a word to the book's collection
  Book addWord(WordEntry word) {
    return copyWith(words: [word, ...words]);
  }

  /// Remove a word from the book's collection
  Book removeWord(String wordId) {
    return copyWith(words: words.where((w) => w.id != wordId).toList());
  }

  /// Update a word in the book's collection
  Book updateWord(WordEntry updatedWord) {
    return copyWith(
      words:
          words.map((w) => w.id == updatedWord.id ? updatedWord : w).toList(),
    );
  }

  /// Get word count
  int get wordCount => words.length;

  /// Check if book has any words
  bool get hasWords => words.isNotEmpty;

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'createdAt': createdAt.toIso8601String(),
      'words': words.map((w) => w.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverUrl: json['coverUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      words:
          (json['words'] as List<dynamic>?)
              ?.map((w) => WordEntry.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Book(id: $id, title: $title, author: $author, words: ${words.length})';
}
