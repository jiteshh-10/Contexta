import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../models/word_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/contexta_app_bar.dart';
import '../widgets/book_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/contexta_dialog.dart';
import '../widgets/logo.dart';
import '../widgets/global_search.dart';
import '../widgets/contexta_bottom_sheet.dart';
import '../widgets/word_explanation_sheet.dart';
import '../widgets/export_options_sheet.dart';
import '../widgets/reading_streak_indicator.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/shelf_overlay.dart';
import '../widgets/add_book_panel.dart';
import '../widgets/book_suggestions_sheet.dart';
import 'book_detail_screen.dart';

/// Current view state for the library screen
enum LibraryView { library, detail }

/// Library screen - main dashboard for book management
/// Features: Book list, shelf animation for adding books, delete confirmation
class LibraryScreen extends StatefulWidget {
  final List<Book> books;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final void Function(String title, String author) onAddBook;
  final void Function(String bookId) onRemoveBook;
  final void Function(Book book) onUpdateBook;
  final bool showReadingStreak;
  final VoidCallback onToggleReadingStreak;
  final Future<void> Function()? onLibraryChanged;

  const LibraryScreen({
    super.key,
    required this.books,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.onAddBook,
    required this.onRemoveBook,
    required this.onUpdateBook,
    required this.showReadingStreak,
    required this.onToggleReadingStreak,
    this.onLibraryChanged,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  LibraryView _view = LibraryView.library;
  Book? _selectedBook;
  WordEntry? _pendingWordToShow;

  // Shelf controller for add book animation
  late ShelfController _shelfController;
  final GlobalKey<ShelfOverlayState> _shelfOverlayKey = GlobalKey();

  // For newly added book highlight
  String? _newlyAddedBookId;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  // Scroll controller for auto-scroll to new book
  final ScrollController _scrollController = ScrollController();

  // FAB animation
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize shelf controller
    _shelfController = ShelfController();

    // FAB animation
    _fabController = AnimationController(
      vsync: this,
      duration: AppTheme.buttonPressDuration,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));

    // Highlight animation for newly added book - Apple-style scale pulse
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Apple-style: subtle scale up then settle (1.0 → 1.03 → 1.0)
    _highlightAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.97,
          end: 1.02,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40, // Quick expand
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.02,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60, // Gentle settle
      ),
    ]).animate(_highlightController);
  }

  @override
  void dispose() {
    _shelfController.dispose();
    _fabController.dispose();
    _highlightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openBook(Book book) {
    setState(() {
      _selectedBook = book;
      _view = LibraryView.detail;
    });
  }

  /// Show delete confirmation and return result
  Future<bool> _confirmDelete(Book book) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Remove Book',
      message:
          "Are you sure you want to remove '${book.title}' from your shelf?",
      confirmLabel: 'Remove',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    return confirmed;
  }

  /// Actually remove the book after animation completes
  void _removeBook(Book book) {
    widget.onRemoveBook(book.id);
  }

  /// Handle search result tap - navigate to book and show word
  void _handleSearchResult(SearchResult result) {
    setState(() {
      _selectedBook = result.book;
      _pendingWordToShow = result.word;
      _view = LibraryView.detail;
    });
  }

  /// Show word details in a bottom sheet
  void _showWordDetails(WordEntry word, Book book) {
    showContextaBottomSheet(
      context: context,
      showCloseButton: false,
      child: WordExplanationSheet(
        entry: word,
        bookTitle: book.title,
        bookAuthor: book.author,
        onClose: () => Navigator.of(context).pop(),
        onRemove: () {
          final updatedBook = book.removeWord(word.id);
          widget.onUpdateBook(updatedBook);
          Navigator.of(context).pop();
        },
        onUpdate: (updatedWord) {
          final updatedBook = book.updateWord(updatedWord);
          widget.onUpdateBook(updatedBook);
        },
      ),
    );
  }

  /// Show export options for all books
  void _showExportAllOptions() {
    showContextaBottomSheet(
      context: context,
      child: ExportOptionsSheet(
        books: widget.books,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Show settings bottom sheet
  void _showSettings() {
    showContextaBottomSheet(
      context: context,
      child: SettingsSheet(
        showReadingStreak: widget.showReadingStreak,
        onToggleReadingStreak: widget.onToggleReadingStreak,
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
        onClose: () => Navigator.of(context).pop(),
        books: widget.books,
        onExportAll: _showExportAllOptions,
        onLibraryChanged: widget.onLibraryChanged,
      ),
    );
  }

  /// Show book suggestions bottom sheet
  void _showBookSuggestions() {
    showContextaBottomSheet(
      context: context,
      child: BookSuggestionsSheet(
        books: widget.books,
        onAddBook: (title, author) {
          widget.onAddBook(title, author);
        },
        onClose: () => Navigator.of(context).pop(),
        onNavigateToAddBook: () {
          _shelfController.open();
        },
      ),
    );
  }

  /// Handle book placement from shelf
  void _handleBookPlacement(
    String title,
    String author,
    Offset cardPosition,
    Size cardSize,
  ) {
    // Start the flying book animation
    _shelfOverlayKey.currentState?.startBookPlacement(
      title: title,
      author: author,
      startPosition: cardPosition,
      bookSize: cardSize,
    );
  }

  /// Called when book placement animation completes
  void _onPlacementComplete(String title, String author) {
    // Add the book
    widget.onAddBook(title, author);

    // Find the newly added book (it will be at the end or beginning of the list)
    // We'll highlight it after the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.books.isNotEmpty) {
        // The new book is typically the last one added
        final newBook = widget.books.last;
        setState(() {
          _newlyAddedBookId = newBook.id;
        });

        // Start highlight animation
        _highlightController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              _newlyAddedBookId = null;
            });
          }
        });

        // Scroll to the new book if needed
        if (_scrollController.hasClients) {
          final index = widget.books.indexWhere((b) => b.id == newBook.id);
          if (index >= 0) {
            // Estimate scroll position (each card ~120px + 16px padding)
            final targetOffset = index * 136.0;
            _scrollController.animateTo(
              targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_view == LibraryView.detail && _selectedBook != null) {
      // Find the current version of the book from the list
      final currentBook = widget.books.firstWhere(
        (b) => b.id == _selectedBook!.id,
        orElse: () => _selectedBook!,
      );

      // Show pending word if coming from search
      if (_pendingWordToShow != null) {
        final wordToShow = _pendingWordToShow!;
        _pendingWordToShow = null;

        // Schedule the bottom sheet to show after the screen is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showWordDetails(wordToShow, currentBook);
          }
        });
      }

      return BookDetailScreen(
        book: currentBook,
        onBack: () {
          setState(() {
            _selectedBook = null;
            _pendingWordToShow = null;
            _view = LibraryView.library;
          });
        },
        onUpdateBook: widget.onUpdateBook,
      );
    }

    // Calculate if any book has words for showing search
    final hasAnyWords = widget.books.any((b) => b.hasWords);

    // Library view with shelf overlay
    return ShelfOverlay(
      key: _shelfOverlayKey,
      controller: _shelfController,
      addBookBuilder:
          (context, onClose) => AddBookPanel(
            onClose: onClose,
            onPlaceOnShelf: (title, author, position, size) {
              _handleBookPlacement(title, author, position, size);
              // Schedule completion callback
              Future.delayed(const Duration(milliseconds: 500), () {
                _onPlacementComplete(title, author);
              });
            },
          ),
      child: Scaffold(
        appBar: ContextaAppBar(
          title: 'My Shelf',
          showBackButton: false,
          rightAction: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SuggestionsButton(onTap: _showBookSuggestions),
              const SizedBox(width: 4),
              _SettingsButton(onTap: _showSettings),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(context),
        body:
            widget.books.isEmpty
                ? _buildEmptyState(context)
                : _buildBookListWithSearch(hasAnyWords),
      ),
    );
  }

  Widget _buildBookListWithSearch(bool showSearch) {
    return Column(
      children: [
        // Reading streak indicator (subtle consistency note)
        if (widget.showReadingStreak)
          const ReadingStreakIndicator(showDotRow: true),

        // Global search bar (only show if there are words to search)
        if (showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: GlobalSearchBar(
              books: widget.books,
              onResultTap: _handleSearchResult,
            ),
          ),

        // Book list
        Expanded(child: _buildBookList()),
      ],
    );
  }

  Widget _buildFAB(BuildContext context) {
    final isDark = widget.isDarkMode;

    return GestureDetector(
      onTapDown: (_) {
        _fabController.forward();
      },
      onTapUp: (_) {
        _fabController.reverse();
      },
      onTapCancel: () {
        _fabController.reverse();
      },
      onTap: () {
        // Open the shelf with haptic feedback
        HapticFeedback.lightImpact();
        _shelfController.open();
      },
      child: AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow:
                    isDark
                        ? [
                          // Subtle glow for dark mode
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                        : [
                          // Regular shadow for light mode
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo icon
            Logo(variant: LogoVariant.icon, size: LogoSize.lg),

            const SizedBox(height: 32),

            // Message
            Text(
              'Your reading journey begins here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Add your first book to start capturing words.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppTheme.getTextSecondary(context),
              ),
            ),

            const SizedBox(height: 32),

            // Add book button - opens shelf
            PrimaryButton(
              label: 'Add a Book to Your Shelf',
              icon: Icons.add,
              onPressed: () {
                HapticFeedback.lightImpact();
                _shelfController.open();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: widget.books.length,
      itemBuilder: (context, index) {
        final book = widget.books[index];
        final isNewlyAdded = book.id == _newlyAddedBookId;

        return Padding(
          key: ValueKey(book.id),
          padding: const EdgeInsets.only(bottom: 16),
          child: AnimatedBuilder(
            animation: _highlightAnimation,
            builder: (context, child) {
              if (!isNewlyAdded) return child!;

              // Apple-style scale animation - no color effects
              return Transform.scale(
                scale: _highlightAnimation.value,
                child: child,
              );
            },
            child: BookCard(
              key: ValueKey('book_card_${book.id}'),
              book: book,
              onTap: () => _openBook(book),
              onDelete: () => _confirmDelete(book),
              onRemoved: () => _removeBook(book),
            ),
          ),
        );
      },
    );
  }
}

/// Book suggestions button - open book icon with tooltip
class _SuggestionsButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SuggestionsButton({required this.onTap});

  @override
  State<_SuggestionsButton> createState() => _SuggestionsButtonState();
}

class _SuggestionsButtonState extends State<_SuggestionsButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Reading suggestions',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: AppTheme.buttonPressDuration,
          scale: _isPressed ? 0.9 : 1.0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _isPressed
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              color: Theme.of(context).colorScheme.onSurface,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings button for accessing app settings
class _SettingsButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SettingsButton({required this.onTap});

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: AppTheme.buttonPressDuration,
        scale: _isPressed ? 0.9 : 1.0,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _isPressed
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
          ),
          child: Icon(
            Icons.settings_outlined,
            color: Theme.of(context).colorScheme.onSurface,
            size: 22,
          ),
        ),
      ),
    );
  }
}
