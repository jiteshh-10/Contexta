import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/book.dart';
import '../models/book_suggestion.dart';
import '../services/book_suggestion_service.dart';
import 'empty_shelf_suggestions.dart';
import 'suggestions_list.dart';

/// Main bottom sheet for book suggestions
///
/// Behavior:
/// - User-initiated only (never auto-shows)
/// - Shows empty state if no books on shelf
/// - Shows personalized suggestions if books exist
/// - Respects user's choice to close
class BookSuggestionsSheet extends StatefulWidget {
  final List<Book> books;
  final void Function(String title, String author) onAddBook;
  final VoidCallback onClose;
  final VoidCallback onNavigateToAddBook;

  const BookSuggestionsSheet({
    super.key,
    required this.books,
    required this.onAddBook,
    required this.onClose,
    required this.onNavigateToAddBook,
  });

  @override
  State<BookSuggestionsSheet> createState() => _BookSuggestionsSheetState();
}

class _BookSuggestionsSheetState extends State<BookSuggestionsSheet> {
  final BookSuggestionService _suggestionService = BookSuggestionService();

  List<BookSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.books.isNotEmpty) {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _suggestionService.getSuggestions(books: widget.books);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _suggestions = result.suggestions;
      } else {
        _error = result.error;
      }
    });
  }

  void _handleAddToShelf(BookSuggestion suggestion) {
    // Add the book
    widget.onAddBook(suggestion.title, suggestion.author);

    // Remove from suggestions list
    setState(() {
      _suggestions.removeWhere((s) => s == suggestion);
    });

    // If no more suggestions, close sheet
    if (_suggestions.isEmpty) {
      widget.onClose();
    }
  }

  void _handleDismiss(BookSuggestion suggestion) {
    setState(() {
      _suggestions.removeWhere((s) => s == suggestion);
    });

    // If all dismissed, close sheet
    if (_suggestions.isEmpty) {
      widget.onClose();
    }
  }

  void _handleAddFirstBook() {
    widget.onClose();
    widget.onNavigateToAddBook();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title bar with subtle heading
        _buildTitleBar(context),

        // Content based on shelf state
        if (widget.books.isEmpty)
          EmptyShelfSuggestions(
            onAddBook: _handleAddFirstBook,
            showTimelessSuggestions: true,
          )
        else
          SuggestionsList(
            suggestions: _suggestions,
            onAddToShelf: _handleAddToShelf,
            onDismiss: _handleDismiss,
            isLoading: _isLoading,
            error: _error,
            onRetry: _loadSuggestions,
          ),
      ],
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Row(
        children: [
          // Icon
          Icon(
            Icons.auto_stories_outlined,
            size: 20,
            color: AppTheme.getTextMuted(context),
          ),

          const SizedBox(width: 10),

          // Title
          Text(
            'Reading Suggestions',
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextPrimary(context),
            ),
          ),

          const Spacer(),

          // Refresh button (only when has books and not loading)
          if (widget.books.isNotEmpty && !_isLoading && _error == null)
            _RefreshButton(onTap: _loadSuggestions),
        ],
      ),
    );
  }
}

/// Subtle refresh button
class _RefreshButton extends StatefulWidget {
  final VoidCallback onTap;

  const _RefreshButton({required this.onTap});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _rotationController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: Tooltip(
        message: 'Get fresh suggestions',
        child: AnimatedScale(
          duration: AppTheme.buttonPressDuration,
          scale: _isPressed ? 0.9 : 1.0,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _isPressed ? AppTheme.getBorder(context) : Colors.transparent,
            ),
            child: RotationTransition(
              turns: _rotationController,
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppTheme.getTextMuted(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
