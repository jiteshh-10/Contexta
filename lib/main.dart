import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/library_screen.dart';
import 'screens/ownership_choice_screen.dart';
import 'models/book.dart';
import 'services/storage_service.dart';
import 'services/database/database_service.dart';
import 'services/connectivity_service.dart';
import 'services/reading_streak_service.dart';
import 'services/auth_service.dart';
import 'services/backup_service.dart';
import 'services/llm_credentials_service.dart';

/// Global flag indicating if Firebase is available
bool isFirebaseAvailable = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env').catchError((_) {
    // .env file not found - will use fallback in ApiConfig
    debugPrint('Warning: .env file not found. API features may not work.');
  });

  // Initialize Firebase with generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseAvailable = true;
    debugPrint('Firebase: Initialized successfully');
  } catch (e) {
    isFirebaseAvailable = false;
    debugPrint('Firebase: Not configured - cloud backup disabled. Error: $e');
  }

  // Initialize services
  await _initializeServices();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ContextaApp());
}

/// Initialize all required services
Future<void> _initializeServices() async {
  // Initialize storage service (SharedPreferences)
  await StorageService().initialize();

  // Initialize SQLite database for offline-first caching
  await DatabaseService().database;
  debugPrint('DatabaseService: Initialized');

  // Initialize connectivity monitoring
  await ConnectivityService().initialize();
  debugPrint('ConnectivityService: Initialized');

  // Initialize reading streak tracking
  await ReadingStreakService().initialize();
  debugPrint('ReadingStreakService: Initialized');

  // Initialize auth service (for backup/restore)
  await AuthService().initialize();
  debugPrint('AuthService: Initialized');

  // Initialize secure LLM credentials storage
  await LlmCredentialsService().initialize();
  debugPrint('LlmCredentialsService: Initialized');
}

/// Main application widget
/// Manages theme state and splash screen transition
class ContextaApp extends StatefulWidget {
  const ContextaApp({super.key});

  @override
  State<ContextaApp> createState() => _ContextaAppState();
}

class _ContextaAppState extends State<ContextaApp> with WidgetsBindingObserver {
  bool _showSplash = true;
  bool _isFirstLaunch = false;
  ThemeMode _themeMode = ThemeMode.system;

  // Books state - centralized for persistence
  List<Book> _books = [];

  // Reading streak visibility setting
  bool _showReadingStreak = true;

  // Storage service instance
  final StorageService _storage = StorageService();
  final AuthService _authService = AuthService();
  final BackupService _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up services to prevent memory leaks
    ConnectivityService().dispose();
    ReadingStreakService().dispose();
    _authService.dispose();
    _backupService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Trigger backup when app goes to background
    if (state == AppLifecycleState.paused) {
      _backupService.performImmediateBackup();
    }
  }

  /// Initialize app: load saved data and handle splash timing
  Future<void> _initializeApp() async {
    // Check if this is first launch
    _isFirstLaunch = await _authService.isFirstLaunch();

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
    debugPrint('_loadSavedData: called');
    try {
      // Load books
      final savedBooks = await _storage.loadBooks();
      debugPrint('_loadSavedData: loaded books count: \\${savedBooks.length}');

      // Load theme preference
      final savedTheme = _storage.loadThemeMode();
      ThemeMode themeMode = ThemeMode.system;
      if (savedTheme == 'light') {
        themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        themeMode = ThemeMode.dark;
      }
      debugPrint('_loadSavedData: loaded theme: \\$savedTheme');

      // Load reading streak visibility preference
      final showReadingStreak = _storage.loadShowReadingStreak();
      debugPrint(
        '_loadSavedData: loaded showReadingStreak: \\$showReadingStreak',
      );

      if (mounted) {
        setState(() {
          _books = savedBooks;
          _themeMode = themeMode;
          _showReadingStreak = showReadingStreak;
        });
        debugPrint('_loadSavedData: state updated');
      } else {
        debugPrint('_loadSavedData: not mounted, state not updated');
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

    // Schedule cloud backup
    _backupService.scheduleBackup();
  }

  /// Remove a book from the library
  void _removeBook(String bookId) {
    setState(() {
      _books = _books.where((book) => book.id != bookId).toList();
    });

    // Persist to storage
    _storage.saveBooks(_books);

    // Schedule cloud backup
    _backupService.scheduleBackup();
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

    // Schedule cloud backup
    _backupService.scheduleBackup();
  }

  /// Toggle reading streak visibility
  void _toggleReadingStreak() {
    setState(() {
      _showReadingStreak = !_showReadingStreak;
    });

    // Persist preference
    _storage.saveShowReadingStreak(_showReadingStreak);

    // Haptic feedback
    HapticFeedback.lightImpact();
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
                : _isFirstLaunch
                ? OwnershipChoiceScreen(
                  key: const ValueKey('ownership'),
                  onChoiceComplete: () {
                    debugPrint(
                      'Main: onChoiceComplete called, setting _isFirstLaunch = false',
                    );
                    setState(() {
                      _isFirstLaunch = false;
                    });
                  },
                  onLibraryChanged: _loadSavedData,
                )
                : LibraryScreen(
                  key: const ValueKey('library'),
                  books: _books,
                  onToggleTheme: _toggleTheme,
                  isDarkMode: _isDarkMode,
                  onAddBook: _addBook,
                  onRemoveBook: _removeBook,
                  onUpdateBook: _updateBook,
                  showReadingStreak: _showReadingStreak,
                  onToggleReadingStreak: _toggleReadingStreak,
                  onLibraryChanged: _loadSavedData,
                ),
      ),
    );
  }
}
