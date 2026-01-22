import 'package:flutter/material.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/contexta_app_bar.dart';
import '../widgets/book_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/contexta_dialog.dart';
import '../widgets/logo.dart';
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

      return BookDetailScreen(
        book: currentBook,
        onBack: () {
          setState(() {
            _selectedBook = null;
            _view = LibraryView.library;
          });
        },
        onUpdateBook: widget.onUpdateBook,
      );
    }

    // Library view
    return Scaffold(
      appBar: ContextaAppBar(
        title: 'My Books',
        showBackButton: false,
        rightAction: _ThemeToggleButton(
          isDarkMode: widget.isDarkMode,
          onTap: widget.onToggleTheme,
        ),
      ),
      floatingActionButton: _buildFAB(context),
      body: widget.books.isEmpty ? _buildEmptyState(context) : _buildBookList(),
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
