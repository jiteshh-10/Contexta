/// Model for book suggestions
/// Represents a thoughtful reading recommendation with reasoning
class BookSuggestion {
  final String title;
  final String author;
  final String reason;
  final String? coverUrl;

  const BookSuggestion({
    required this.title,
    required this.author,
    required this.reason,
    this.coverUrl,
  });

  /// Create from JSON response
  factory BookSuggestion.fromJson(Map<String, dynamic> json) {
    return BookSuggestion(
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'reason': reason,
      if (coverUrl != null) 'coverUrl': coverUrl,
    };
  }

  /// Check if suggestion matches a book already on shelf
  bool matchesBook(String bookTitle, String bookAuthor) {
    final normalizedTitle = title.toLowerCase().trim();
    final normalizedAuthor = author.toLowerCase().trim();
    final shelfTitle = bookTitle.toLowerCase().trim();
    final shelfAuthor = bookAuthor.toLowerCase().trim();

    return normalizedTitle == shelfTitle ||
        (normalizedAuthor == shelfAuthor &&
            _similarTitles(normalizedTitle, shelfTitle));
  }

  /// Check if titles are similar (for duplicate detection)
  bool _similarTitles(String a, String b) {
    // Remove common articles and punctuation
    String normalize(String s) {
      return s
          .replaceAll(RegExp(r'^(the|a|an)\s+'), '')
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();
    }

    return normalize(a) == normalize(b);
  }

  @override
  String toString() => 'BookSuggestion(title: $title, author: $author)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookSuggestion &&
        other.title.toLowerCase() == title.toLowerCase() &&
        other.author.toLowerCase() == author.toLowerCase();
  }

  @override
  int get hashCode =>
      title.toLowerCase().hashCode ^ author.toLowerCase().hashCode;
}

/// Timeless classics for empty shelf state
/// These are universally recognized starting points
class TimelessSuggestions {
  TimelessSuggestions._();

  static const List<BookSuggestion> classics = [
    BookSuggestion(
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      reason: 'A timeless exploration of justice and moral growth.',
    ),
    BookSuggestion(
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      reason: 'A witty examination of society and human nature.',
    ),
    BookSuggestion(
      title: '1984',
      author: 'George Orwell',
      reason: 'A profound meditation on power and truth.',
    ),
  ];
}
