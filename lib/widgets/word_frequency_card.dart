import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/word_entry.dart';
import '../theme/app_theme.dart';

/// A card displaying top difficult words with lookup frequency badges
/// Shows words that users repeatedly look up, indicating challenging vocabulary
class WordFrequencyCard extends StatefulWidget {
  final List<WordEntry> topWords;
  final void Function(WordEntry word) onWordTap;
  final VoidCallback? onViewAll;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const WordFrequencyCard({
    super.key,
    required this.topWords,
    required this.onWordTap,
    this.onViewAll,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  @override
  State<WordFrequencyCard> createState() => _WordFrequencyCardState();
}

class _WordFrequencyCardState extends State<WordFrequencyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(WordFrequencyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topWords.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = AppTheme.isDark(context);
    final displayWords =
        widget.isExpanded ? widget.topWords : widget.topWords.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.getBorder(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppTheme.charcoal).withValues(
              alpha: 0.06,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(context),

          // Word list
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Column(
              children: [
                ...displayWords.asMap().entries.map((entry) {
                  final index = entry.key;
                  final word = entry.value;
                  return _WordFrequencyItem(
                    entry: word,
                    rank: index + 1,
                    onTap: () => widget.onWordTap(word),
                    showDivider: index < displayWords.length - 1,
                  );
                }),
              ],
            ),
          ),

          // Expand/Collapse button
          if (widget.topWords.length > 5 && widget.onToggleExpand != null)
            _buildExpandButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenging Words',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Words you\'ve looked up multiple times',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onToggleExpand?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.getBorder(context), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: widget.isExpanded ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.isExpanded
                  ? 'Show Less'
                  : 'Show All ${widget.topWords.length}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual word item in the frequency list
class _WordFrequencyItem extends StatefulWidget {
  final WordEntry entry;
  final int rank;
  final VoidCallback onTap;
  final bool showDivider;

  const _WordFrequencyItem({
    required this.entry,
    required this.rank,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  State<_WordFrequencyItem> createState() => _WordFrequencyItemState();
}

class _WordFrequencyItemState extends State<_WordFrequencyItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: AppTheme.buttonPressDuration,
        decoration: BoxDecoration(
          color:
              _isPressed
                  ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Rank indicator
                  _buildRankBadge(context),
                  const SizedBox(width: 12),

                  // Word
                  Expanded(
                    child: Text(
                      widget.entry.capitalizedWord,
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),

                  // Lookup count badge
                  _buildCountBadge(context),

                  const SizedBox(width: 8),

                  // Arrow indicator
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.getTextMuted(context),
                  ),
                ],
              ),
            ),
            if (widget.showDivider)
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Container(
                  height: 1,
                  color: AppTheme.getBorder(context).withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(BuildContext context) {
    final Color badgeColor;
    final Color textColor;

    // Gold, Silver, Bronze for top 3
    switch (widget.rank) {
      case 1:
        badgeColor = const Color(0xFFD4AF37).withValues(alpha: 0.2);
        textColor = const Color(0xFFB8860B);
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0).withValues(alpha: 0.3);
        textColor = const Color(0xFF808080);
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32).withValues(alpha: 0.2);
        textColor = const Color(0xFFCD7F32);
        break;
      default:
        badgeColor = AppTheme.getBorder(context).withValues(alpha: 0.5);
        textColor = AppTheme.getTextMuted(context);
    }

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${widget.rank}',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCountBadge(BuildContext context) {
    final count = widget.entry.lookupCount;
    final isHighFrequency = count >= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isHighFrequency
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : AppTheme.getBorder(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 12,
            color:
                isHighFrequency
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.getTextMuted(context),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isHighFrequency
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
