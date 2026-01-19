import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../models/word_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/contexta_app_bar.dart';
import '../widgets/contexta_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/word_list_item.dart';
import '../widgets/word_explanation_sheet.dart';
import '../widgets/loading_dots.dart';
import '../widgets/contexta_bottom_sheet.dart';
import '../services/perplexity_service.dart';

/// Sort options for word collection
enum SortOption {
  recent('Recently Added'),
  oldest('Oldest First'),
  alphabetical('A–Z'),
  reverseAlphabetical('Z–A');

  final String label;
  const SortOption(this.label);
}

/// Book detail screen for word exploration
/// Features: Word input, explain action, loading state, sorting, word management
class BookDetailScreen extends StatefulWidget {
  final Book book;
  final VoidCallback onBack;
  final void Function(Book book) onUpdateBook;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.onBack,
    required this.onUpdateBook,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final TextEditingController _wordController = TextEditingController();
  final FocusNode _wordFocusNode = FocusNode();
  final PerplexityService _perplexityService = PerplexityService();

  bool _isLoading = false;
  String? _errorMessage;
  SortOption _sortOption = SortOption.recent;

  @override
  void dispose() {
    _wordController.dispose();
    _wordFocusNode.dispose();
    super.dispose();
  }

  /// Get sorted words based on current sort option
  List<WordEntry> get _sortedWords {
    final words = [...widget.book.words];

    switch (_sortOption) {
      case SortOption.recent:
        words.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case SortOption.oldest:
        words.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case SortOption.alphabetical:
        words.sort(
          (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()),
        );
        break;
      case SortOption.reverseAlphabetical:
        words.sort(
          (a, b) => b.word.toLowerCase().compareTo(a.word.toLowerCase()),
        );
        break;
    }

    return words;
  }

  /// Handle word explanation using Perplexity API
  void _explainWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) return;

    // Clear any previous error
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Call Perplexity API for contextual explanation
    final result = await _perplexityService.explainWord(
      word: word,
      bookTitle: widget.book.title,
      bookAuthor: widget.book.author,
    );

    if (!mounted) return;

    if (result.success && result.explanation != null) {
      // Create new word entry with API explanation
      final newWord = WordEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        word: word,
        explanation: result.explanation!,
        bookId: widget.book.id,
      );

      // Update book with new word
      final updatedBook = widget.book.addWord(newWord);
      widget.onUpdateBook(updatedBook);

      // Clear input and reset state
      _wordController.clear();
      setState(() => _isLoading = false);

      // Haptic feedback on success
      HapticFeedback.mediumImpact();

      // Refocus input
      _wordFocusNode.requestFocus();
    } else {
      // Handle error - show error message and keep word in input
      setState(() {
        _isLoading = false;
        _errorMessage =
            result.error ?? 'Failed to get explanation. Please try again.';
      });

      // Haptic feedback on error
      HapticFeedback.heavyImpact();

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _explainWord,
            ),
          ),
        );
      }
    }
  }

  /// Show sort options
  void _showSortOptions() {
    showContextaBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sort Collection',
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...SortOption.values.map((option) => _buildSortOption(option)),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(SortOption option) {
    final isSelected = _sortOption == option;

    return GestureDetector(
      onTap: () {
        setState(() => _sortOption = option);
        HapticFeedback.selectionClick();
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.getBorder(context),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  /// Show word details
  void _showWordDetails(WordEntry word) {
    showContextaBottomSheet(
      context: context,
      showCloseButton: false,
      child: WordExplanationSheet(
        entry: word,
        bookTitle: widget.book.title,
        bookAuthor: widget.book.author,
        onClose: () {
          Navigator.of(context).pop();
        },
        onRemove: () => _removeWord(word),
        onUpdate: (updatedWord) => _updateWord(updatedWord),
        onRefetchExplanation: (newWord) => _getExplanation(newWord),
      ),
    );
  }

  /// Get explanation for a word from Perplexity API
  Future<String?> _getExplanation(String word) async {
    final result = await _perplexityService.explainWord(
      word: word,
      bookTitle: widget.book.title,
      bookAuthor: widget.book.author,
    );

    if (result.success && result.explanation != null) {
      return result.explanation;
    }
    return null;
  }

  /// Remove a word from the collection
  void _removeWord(WordEntry word) {
    HapticFeedback.mediumImpact();
    final updatedBook = widget.book.removeWord(word.id);
    widget.onUpdateBook(updatedBook);
  }

  /// Update a word in the collection
  void _updateWord(WordEntry updatedWord) {
    final updatedBook = widget.book.updateWord(updatedWord);
    widget.onUpdateBook(updatedBook);
  }

  @override
  Widget build(BuildContext context) {
    final sortedWords = _sortedWords;

    return Scaffold(
      appBar: ContextaAppBar(title: widget.book.title, onBack: widget.onBack),
      body: CustomScrollView(
        slivers: [
          // Word input card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWordInputCard(),
            ),
          ),

          // Divider and sort controls
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCollectionHeader(),
            ),
          ),

          // Word list or empty state
          if (sortedWords.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: WordListItem(
                    entry: sortedWords[index],
                    onTap: () => _showWordDetails(sortedWords[index]),
                    showDivider: index < sortedWords.length - 1,
                  ),
                ),
                childCount: sortedWords.length,
              ),
            ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildWordInputCard() {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppTheme.charcoal).withValues(
              alpha: 0.1,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Word input field
          ContextaTextField(
            placeholder: 'Enter a word you paused at',
            value: _wordController.text,
            onChanged: (v) => setState(() => _wordController.text = v),
            onSubmitted:
                !_isLoading && _wordController.text.trim().isNotEmpty
                    ? _explainWord
                    : null,
            disabled: _isLoading,
            focusNode: _wordFocusNode,
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: 16),

          // Explain button
          PrimaryButton(
            label: 'Explain',
            icon: Icons.auto_awesome_outlined,
            fullWidth: true,
            disabled: _isLoading || _wordController.text.trim().isEmpty,
            onPressed: _explainWord,
          ),

          // Loading state
          if (_isLoading) const LoadingDots(),
        ],
      ),
    );
  }

  Widget _buildCollectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Left divider
          Expanded(
            child: Container(height: 1, color: AppTheme.getBorder(context)),
          ),

          // Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'YOUR COLLECTION',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
                color: AppTheme.getTextMuted(context),
              ),
            ),
          ),

          // Right divider
          Expanded(
            child: Container(height: 1, color: AppTheme.getBorder(context)),
          ),

          // Sort button (only show if there are words)
          if (widget.book.words.isNotEmpty) ...[
            const SizedBox(width: 12),
            _SortButton(currentSort: _sortOption, onTap: _showSortOptions),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 48,
            color: AppTheme.getTextMuted(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No words noted yet.',
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Words you explore will appear here.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sort button with current sort indicator
class _SortButton extends StatefulWidget {
  final SortOption currentSort;
  final VoidCallback onTap;

  const _SortButton({required this.currentSort, required this.onTap});

  @override
  State<_SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends State<_SortButton> {
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
        scale: _isPressed ? 0.95 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                _isPressed
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.getBorder(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.currentSort.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
