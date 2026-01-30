import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../models/word_entry.dart';
import '../theme/app_theme.dart';
import 'difficulty_reason_selector.dart';

/// Search result containing word and its parent book
class SearchResult {
  final WordEntry word;
  final Book book;

  const SearchResult({required this.word, required this.book});
}

/// Global search bar for searching words across all books
/// Features: Bookmark-style reveal animation, subtle slide-in results
class GlobalSearchBar extends StatefulWidget {
  final List<Book> books;
  final void Function(SearchResult result) onResultTap;
  final VoidCallback? onSearchOpened;
  final VoidCallback? onSearchClosed;

  const GlobalSearchBar({
    super.key,
    required this.books,
    required this.onResultTap,
    this.onSearchOpened,
    this.onSearchClosed,
  });

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _expandController;
  late final AnimationController _resultsController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _ribbonAnimation;

  bool _isExpanded = false;
  List<SearchResult> _results = [];

  @override
  void initState() {
    super.initState();

    // Expand animation for search bar reveal
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Ribbon bookmark animation - slight overshoot
    _ribbonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Results fade-in controller
    _resultsController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _expandController.dispose();
    _resultsController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _controller.text.isEmpty) {
      _collapse();
    }
  }

  void _onSearchChanged() {
    final query = _controller.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _results = []);
      _resultsController.reverse();
      return;
    }

    // Search across all books
    final results = <SearchResult>[];
    for (final book in widget.books) {
      for (final word in book.words) {
        if (word.word.toLowerCase().contains(query)) {
          results.add(SearchResult(word: word, book: book));
        }
      }
    }

    // Sort by relevance: exact match first, then by recency
    results.sort((a, b) {
      final aExact = a.word.word.toLowerCase() == query;
      final bExact = b.word.word.toLowerCase() == query;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      return b.word.timestamp.compareTo(a.word.timestamp);
    });

    setState(() => _results = results.take(10).toList());

    if (results.isNotEmpty) {
      _resultsController.forward();
    }
  }

  void _expand() {
    if (_isExpanded) return;
    setState(() => _isExpanded = true);
    _expandController.forward();
    widget.onSearchOpened?.call();
    HapticFeedback.lightImpact();

    // Focus after animation starts
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _collapse() {
    if (!_isExpanded) return;
    _focusNode.unfocus();
    _controller.clear();
    setState(() {
      _isExpanded = false;
      _results = [];
    });
    _expandController.reverse();
    _resultsController.reverse();
    widget.onSearchClosed?.call();
  }

  void _handleResultTap(SearchResult result) {
    HapticFeedback.selectionClick();
    _collapse();
    widget.onResultTap(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar with bookmark ribbon effect
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkPaper : AppTheme.paper,
                borderRadius: BorderRadius.circular(
                  12 + (12 * (1 - _expandAnimation.value)),
                ),
                border: Border.all(
                  color:
                      _isExpanded
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3)
                          : AppTheme.getBorder(context),
                  width: _isExpanded ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppTheme.charcoal)
                        .withValues(
                          alpha: 0.08 + (0.04 * _expandAnimation.value),
                        ),
                    blurRadius: 8 + (8 * _expandAnimation.value),
                    offset: Offset(0, 2 + (2 * _expandAnimation.value)),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Bookmark ribbon indicator
                  AnimatedBuilder(
                    animation: _ribbonAnimation,
                    builder: (context, _) {
                      return Container(
                        width: 4,
                        height: 48 * _ribbonAnimation.value,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),

                  // Search icon / button
                  GestureDetector(
                    onTap: _isExpanded ? null : _expand,
                    child: Container(
                      width: 44,
                      height: 48,
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.search_rounded,
                          key: ValueKey(_isExpanded),
                          size: 22,
                          color:
                              _isExpanded
                                  ? Theme.of(context).colorScheme.primary
                                  : AppTheme.getTextMuted(context),
                        ),
                      ),
                    ),
                  ),

                  // Text field or placeholder
                  Expanded(
                    child:
                        _isExpanded
                            ? TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search your words...',
                                hintStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  color: AppTheme.getTextMuted(context),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              textInputAction: TextInputAction.search,
                            )
                            : GestureDetector(
                              onTap: _expand,
                              child: Container(
                                color: Colors.transparent,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Search words',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    color: AppTheme.getTextMuted(context),
                                  ),
                                ),
                              ),
                            ),
                  ),

                  // Clear / close button
                  if (_isExpanded)
                    GestureDetector(
                      onTap: _collapse,
                      child: Container(
                        width: 44,
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppTheme.getTextMuted(context),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // Search results
        if (_results.isNotEmpty)
          FadeTransition(
            opacity: _resultsController,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(_resultsController),
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkPaper : AppTheme.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.getBorder(context)),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : AppTheme.charcoal)
                          .withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      return _SearchResultItem(
                        result: _results[index],
                        query: _controller.text.trim(),
                        onTap: () => _handleResultTap(_results[index]),
                        isLast: index == _results.length - 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

        // Empty state when searching but no results
        if (_isExpanded && _controller.text.isNotEmpty && _results.isEmpty)
          FadeTransition(
            opacity: _expandAnimation,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkPaper : AppTheme.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 32,
                    color: AppTheme.getTextMuted(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No words found',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Individual search result item with word highlight
class _SearchResultItem extends StatefulWidget {
  final SearchResult result;
  final String query;
  final VoidCallback onTap;
  final bool isLast;

  const _SearchResultItem({
    required this.result,
    required this.query,
    required this.onTap,
    required this.isLast,
  });

  @override
  State<_SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<_SearchResultItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              _isPressed
                  ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
          border:
              !widget.isLast
                  ? Border(
                    bottom: BorderSide(
                      color: AppTheme.getBorder(context).withValues(alpha: 0.5),
                    ),
                  )
                  : null,
        ),
        child: Row(
          children: [
            // Book indicator (bookmark style)
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Word and book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Word with highlight
                  _HighlightedWord(
                    word: widget.result.word.capitalizedWord,
                    query: widget.query,
                  ),
                  const SizedBox(height: 4),
                  // Book title
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 12,
                        color: AppTheme.getTextMuted(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.result.book.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppTheme.getTextMuted(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Difficulty badge if present
            if (widget.result.word.difficultyReason != null) ...[
              const SizedBox(width: 8),
              DifficultyReasonBadge(
                reason: widget.result.word.difficultyReason!,
                compact: true,
              ),
            ],

            const SizedBox(width: 8),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.getTextMuted(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text widget that highlights matching query in word
class _HighlightedWord extends StatelessWidget {
  final String word;
  final String query;

  const _HighlightedWord({required this.word, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        word,
        style: TextStyle(
          fontFamily: 'Serif',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    final lowerWord = word.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerWord.indexOf(lowerQuery);

    if (matchIndex < 0) {
      return Text(
        word,
        style: TextStyle(
          fontFamily: 'Serif',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    final before = word.substring(0, matchIndex);
    final match = word.substring(matchIndex, matchIndex + query.length);
    final after = word.substring(matchIndex + query.length);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Serif',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
