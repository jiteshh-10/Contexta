import 'package:flutter/material.dart';
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
import 'add_book_screen.dart';
import 'book_detail_screen.dart';

/// Current view state for the library screen
enum LibraryView { library, add, detail }

/// Library screen - main dashboard for book management
/// Features: Book list, FAB with glow effect, delete confirmation, dark mode toggle
class LibraryScreen extends StatefulWidget {
  final List<Book> books;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final void Function(String title, String author) onAddBook;
  final void Function(String bookId) onRemoveBook;
  final void Function(Book book) onUpdateBook;

  const LibraryScreen({
    super.key,
    required this.books,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.onAddBook,
    required this.onRemoveBook,
    required this.onUpdateBook,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  LibraryView _view = LibraryView.library;
  Book? _selectedBook;
  WordEntry? _pendingWordToShow;

  // FAB animation
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      vsync: this,
      duration: AppTheme.buttonPressDuration,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    // Handle different views
    if (_view == LibraryView.add) {
      return AddBookScreen(
        onBack: () => setState(() => _view = LibraryView.library),
        onSave: (title, author) {
          widget.onAddBook(title, author);
          setState(() => _view = LibraryView.library);
        },
      );
    }

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

    // Library view
    return Scaffold(
      appBar: ContextaAppBar(
        title: 'My Books',
        showBackButton: false,
        rightAction: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Export all button (only show if there are words)
            if (hasAnyWords) _ExportAllButton(onTap: _showExportAllOptions),
            const SizedBox(width: 4),
            _ThemeToggleButton(
              isDarkMode: widget.isDarkMode,
              onTap: widget.onToggleTheme,
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
      body:
          widget.books.isEmpty
              ? _buildEmptyState(context)
              : _buildBookListWithSearch(hasAnyWords),
    );
  }

  Widget _buildBookListWithSearch(bool showSearch) {
    return Column(
      children: [
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
      onTap: () => setState(() => _view = LibraryView.add),
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
                boxShadow: [
                  // Regular shadow
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  // Glow effect for dark mode
                  if (isDark)
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
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

            // Add book button
            PrimaryButton(
              label: 'Add a Book to Your Shelf',
              icon: Icons.add,
              onPressed: () => setState(() => _view = LibraryView.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: widget.books.length,
      itemBuilder: (context, index) {
        final book = widget.books[index];
        return Padding(
          key: ValueKey(book.id),
          padding: const EdgeInsets.only(bottom: 16),
          child: BookCard(
            key: ValueKey('book_card_${book.id}'),
            book: book,
            onTap: () => _openBook(book),
            onDelete: () => _confirmDelete(book),
            onRemoved: () => _removeBook(book),
          ),
        );
      },
    );
  }
}

/// Export all button for exporting vocabulary from all books
class _ExportAllButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ExportAllButton({required this.onTap});

  @override
  State<_ExportAllButton> createState() => _ExportAllButtonState();
}

class _ExportAllButtonState extends State<_ExportAllButton> {
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
            Icons.ios_share_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Theme toggle button with smooth animation
class _ThemeToggleButton extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onTap;

  const _ThemeToggleButton({required this.isDarkMode, required this.onTap});

  @override
  State<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<_ThemeToggleButton> {
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
          child: AnimatedSwitcher(
            duration: AppTheme.cardPressDuration,
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              key: ValueKey(widget.isDarkMode),
              color: Theme.of(context).colorScheme.onSurface,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
