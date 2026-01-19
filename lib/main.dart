import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/library_screen.dart';
import 'models/book.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env').catchError((_) {
    // .env file not found - will use fallback in ApiConfig
    debugPrint('Warning: .env file not found. API features may not work.');
  });

  // Initialize storage service
  await StorageService().initialize();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ContextaApp());
}

/// Main application widget
/// Manages theme state and splash screen transition
class ContextaApp extends StatefulWidget {
  const ContextaApp({super.key});

  @override
  State<ContextaApp> createState() => _ContextaAppState();
}

class _ContextaAppState extends State<ContextaApp> {
  bool _showSplash = true;
  ThemeMode _themeMode = ThemeMode.system;

  // Books state - centralized for persistence
  List<Book> _books = [];

  // Storage service instance
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app: load saved data and handle splash timing
  Future<void> _initializeApp() async {
    // Load saved books and theme preference
    await _loadSavedData();

    // Splash duration: 2.5 seconds as per PRD
    // Wait for remaining time if data loaded faster
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  /// Load saved books and theme from local storage
  Future<void> _loadSavedData() async {
    try {
      // Load books
      final savedBooks = await _storage.loadBooks();

      // Load theme preference
      final savedTheme = _storage.loadThemeMode();
      ThemeMode themeMode = ThemeMode.system;
      if (savedTheme == 'light') {
        themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        themeMode = ThemeMode.dark;
      }

      if (mounted) {
        setState(() {
          _books = savedBooks;
          _themeMode = themeMode;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved data: $e');
    }
  }

  /// Toggle between light and dark theme
  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.system) {
        // Determine current system brightness and toggle opposite
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _themeMode =
            brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
      } else {
        _themeMode =
            _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      }
    });

    // Persist theme preference
    final themeName =
        _themeMode == ThemeMode.light
            ? 'light'
            : _themeMode == ThemeMode.dark
            ? 'dark'
            : 'system';
    _storage.saveThemeMode(themeName);

    // Haptic feedback on theme change
    HapticFeedback.lightImpact();
  }

  /// Check if dark mode is currently active
  bool get _isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Add a new book to the library
  void _addBook(String title, String author) {
    final newBook = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      author: author.trim().isEmpty ? 'Unknown Author' : author.trim(),
    );

    setState(() {
      _books = [newBook, ..._books];
    });

    // Persist to storage
    _storage.saveBooks(_books);
  }

  /// Remove a book from the library
  void _removeBook(String bookId) {
    setState(() {
      _books = _books.where((book) => book.id != bookId).toList();
    });

    // Persist to storage
    _storage.saveBooks(_books);
  }

  /// Update a book in the library
  void _updateBook(Book updatedBook) {
    setState(() {
      _books =
          _books.map((book) {
            return book.id == updatedBook.id ? updatedBook : book;
          }).toList();
    });

    // Persist to storage
    _storage.saveBooks(_books);
  }

  @override
  Widget build(BuildContext context) {
    // Update system UI overlay style based on theme
    final isDark = _isDarkMode;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            isDark ? AppTheme.darkBackground : AppTheme.beige,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Contexta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: AnimatedSwitcher(
        duration: AppTheme.themeTransitionDuration,
        child:
            _showSplash
                ? const SplashScreen(key: ValueKey('splash'))
                : LibraryScreen(
                  key: const ValueKey('library'),
                  books: _books,
                  onToggleTheme: _toggleTheme,
                  isDarkMode: _isDarkMode,
                  onAddBook: _addBook,
                  onRemoveBook: _removeBook,
                  onUpdateBook: _updateBook,
                ),
      ),
    );
  }
}
