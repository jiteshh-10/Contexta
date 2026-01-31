import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for author name suggestions
/// Combines curated literary authors with previously used authors
class AuthorSuggestionService {
  // Singleton pattern
  static final AuthorSuggestionService _instance =
      AuthorSuggestionService._internal();
  factory AuthorSuggestionService() => _instance;
  AuthorSuggestionService._internal();

  SharedPreferences? _prefs;
  static const String _usedAuthorsKey = 'contexta_used_authors';

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get suggestions for author name
  /// Returns max 3 suggestions, prioritizing previously used authors
  Future<List<String>> getSuggestions(String query) async {
    if (query.length < 2) return [];

    final queryLower = query.toLowerCase().trim();
    if (queryLower.isEmpty) return [];

    // Get previously used authors (prioritized)
    final usedAuthors = await _getUsedAuthors();

    // Combine: used authors first, then curated list
    final allAuthors = <String>{...usedAuthors, ..._curatedAuthors};

    // Filter by query - check if any word in author name starts with query
    // or if the full name contains the query
    final matches =
        allAuthors.where((author) {
          final authorLower = author.toLowerCase();

          // Check if any word starts with query
          final words = authorLower.split(' ');
          for (final word in words) {
            if (word.startsWith(queryLower)) return true;
          }

          // Check if full name contains query (for partial matches)
          return authorLower.contains(queryLower);
        }).toList();

    // Sort by relevance:
    // 1. Previously used authors first
    // 2. Then by how early the match appears
    matches.sort((a, b) {
      final aUsed = usedAuthors.contains(a);
      final bUsed = usedAuthors.contains(b);

      // Used authors first
      if (aUsed && !bUsed) return -1;
      if (!aUsed && bUsed) return 1;

      // Then by match position
      final aIndex = a.toLowerCase().indexOf(queryLower);
      final bIndex = b.toLowerCase().indexOf(queryLower);
      return aIndex.compareTo(bIndex);
    });

    // Return max 3
    return matches.take(3).toList();
  }

  /// Record an author as used (for future prioritization)
  Future<void> recordAuthor(String author) async {
    if (author.trim().isEmpty) return;

    await initialize();
    final usedAuthors = await _getUsedAuthors();

    // Add to front of list (most recent first)
    usedAuthors.remove(author.trim());
    usedAuthors.insert(0, author.trim());

    // Keep max 50 used authors
    if (usedAuthors.length > 50) {
      usedAuthors.removeRange(50, usedAuthors.length);
    }

    await _prefs?.setString(_usedAuthorsKey, jsonEncode(usedAuthors));
  }

  /// Get list of previously used authors
  Future<List<String>> _getUsedAuthors() async {
    await initialize();
    final encoded = _prefs?.getString(_usedAuthorsKey);
    if (encoded == null || encoded.isEmpty) return [];

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// Curated list of classic and notable authors
  /// Focused on literary authors commonly read with challenging vocabulary
  static const List<String> _curatedAuthors = [
    // Classic Literature
    'Fyodor Dostoevsky',
    'Leo Tolstoy',
    'Anton Chekhov',
    'Jane Austen',
    'Charles Dickens',
    'William Shakespeare',
    'Herman Melville',
    'Mark Twain',
    'Oscar Wilde',
    'Emily Brontë',
    'Charlotte Brontë',
    'Virginia Woolf',
    'James Joyce',
    'Franz Kafka',
    'Marcel Proust',
    'Thomas Hardy',
    'George Eliot',
    'Gustave Flaubert',
    'Victor Hugo',
    'Alexandre Dumas',
    'Honoré de Balzac',
    'Émile Zola',

    // American Literature
    'Ernest Hemingway',
    'F. Scott Fitzgerald',
    'William Faulkner',
    'John Steinbeck',
    'Harper Lee',
    'Toni Morrison',
    'Ralph Ellison',
    'Nathaniel Hawthorne',
    'Edgar Allan Poe',
    'Henry James',
    'Edith Wharton',
    'Jack London',
    'Kurt Vonnegut',
    'Saul Bellow',
    'Philip Roth',
    'Cormac McCarthy',
    'Don DeLillo',
    'Thomas Pynchon',

    // British Modern
    'George Orwell',
    'Aldous Huxley',
    'Graham Greene',
    'Evelyn Waugh',
    'E.M. Forster',
    'D.H. Lawrence',
    'Joseph Conrad',
    'Rudyard Kipling',
    'W. Somerset Maugham',
    'Ian McEwan',
    'Kazuo Ishiguro',
    'Zadie Smith',
    'Julian Barnes',
    'Martin Amis',

    // World Literature
    'Gabriel García Márquez',
    'Jorge Luis Borges',
    'Julio Cortázar',
    'Mario Vargas Llosa',
    'Pablo Neruda',
    'Octavio Paz',
    'Albert Camus',
    'Jean-Paul Sartre',
    'Simone de Beauvoir',
    'Umberto Eco',
    'Italo Calvino',
    'Luigi Pirandello',
    'Hermann Hesse',
    'Thomas Mann',
    'Günter Grass',
    'Milan Kundera',
    'Chinua Achebe',
    'Chimamanda Ngozi Adichie',
    'Haruki Murakami',
    'Yukio Mishima',
    'Orhan Pamuk',
    'Salman Rushdie',
    'V.S. Naipaul',
    'Arundhati Roy',

    // Philosophy & Essays
    'Friedrich Nietzsche',
    'Søren Kierkegaard',
    'Arthur Schopenhauer',
    'Michel de Montaigne',
    'Bertrand Russell',
    'Hannah Arendt',
    'Simone Weil',

    // Poetry
    'T.S. Eliot',
    'W.B. Yeats',
    'Emily Dickinson',
    'Walt Whitman',
    'Robert Frost',
    'Sylvia Plath',
    'Rainer Maria Rilke',
    'Federico García Lorca',

    // Contemporary Literary Fiction
    'Margaret Atwood',
    'Michael Ondaatje',
    'Anne Carson',
    'Marilynne Robinson',
    'Jonathan Franzen',
    'Jeffrey Eugenides',
    'Donna Tartt',
    'Colson Whitehead',
    'Hanya Yanagihara',
    'Ocean Vuong',
    'Sally Rooney',
    'Elena Ferrante',

    // Science Fiction & Fantasy (Literary)
    'Ursula K. Le Guin',
    'Isaac Asimov',
    'Arthur C. Clarke',
    'Philip K. Dick',
    'Ray Bradbury',
    'J.R.R. Tolkien',
    'C.S. Lewis',
    'Neil Gaiman',

    // Mystery & Thriller (Literary)
    'Agatha Christie',
    'Arthur Conan Doyle',
    'Raymond Chandler',
    'Dashiell Hammett',

    // Non-Fiction (Literary)
    'George Orwell',
    'Christopher Hitchens',
    'Joan Didion',
    'Annie Dillard',
    'Rebecca Solnit',
    'Pico Iyer',
  ];
}
