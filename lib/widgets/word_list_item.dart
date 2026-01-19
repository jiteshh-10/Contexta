import 'package:flutter/material.dart';
import '../models/word_entry.dart';
import '../theme/app_theme.dart';

/// Word list item with tap feedback and relative timestamps
/// Features: Serif bold word, 2-line explanation, active brightness effect
class WordListItem extends StatefulWidget {
  final WordEntry entry;
  final VoidCallback onTap;
  final bool showDivider;

  const WordListItem({
    super.key,
    required this.entry,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  State<WordListItem> createState() => _WordListItemState();
}

class _WordListItemState extends State<WordListItem> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.listItemDuration,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color:
                _isPressed
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08)
                    : _isHovered
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.04)
                    : Colors.transparent,
            border:
                widget.showDivider
                    ? Border(
                      bottom: BorderSide(
                        color: AppTheme.getBorder(context),
                        width: 1,
                      ),
                    )
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Word info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Word title
                      Text(
                        widget.entry.capitalizedWord,
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Explanation preview (2 lines)
                      Text(
                        widget.entry.explanation,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          height: 1.4,
                          color: AppTheme.getTextSecondary(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Timestamp
                Container(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.entry.relativeTime,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.getTextMuted(context),
                    ),
                  ),
                ),

                // Chevron indicator
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppTheme.getTextMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
