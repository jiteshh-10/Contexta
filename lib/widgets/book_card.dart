import 'package:flutter/material.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';

/// Book card with stacked paper effect and animations
/// Features: Press animation (scale 0.98), hover (scale 1.01), delete button
class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  bool _isDeleting = false;

  double get _scale {
    if (_isPressed) return AppTheme.cardPressedScale;
    if (_isHovered) return AppTheme.cardHoverScale;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return AnimatedOpacity(
      duration: AppTheme.sheetAnimDuration,
      opacity: _isDeleting ? 0.0 : 1.0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            duration: AppTheme.cardPressDuration,
            scale: _scale,
            curve: Curves.easeOut,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Stacked paper effect - bottom layer
                Positioned(
                  left: 6,
                  right: 6,
                  top: 8,
                  bottom: -4,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppTheme.darkPaper.withValues(alpha: 0.5)
                              : AppTheme.paper.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : AppTheme.charcoal)
                              .withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stacked paper effect - middle layer
                Positioned(
                  left: 3,
                  right: 3,
                  top: 4,
                  bottom: -2,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppTheme.darkPaper.withValues(alpha: 0.7)
                              : AppTheme.paper.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : AppTheme.charcoal)
                              .withValues(alpha: 0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main card
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : AppTheme.charcoal)
                            .withValues(alpha: _isPressed ? 0.1 : 0.15),
                        blurRadius: _isPressed ? 4 : 8,
                        offset: Offset(0, _isPressed ? 2 : 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Book cover placeholder or image
                        Container(
                          width: 48,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                            border: Border.all(
                              color: AppTheme.getBorder(context),
                              width: 1,
                            ),
                          ),
                          child:
                              widget.book.coverUrl != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                    child: Image.network(
                                      widget.book.coverUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              _buildCoverPlaceholder(context),
                                    ),
                                  )
                                  : _buildCoverPlaceholder(context),
                        ),

                        const SizedBox(width: 16),

                        // Book info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.book.title,
                                style: TextStyle(
                                  fontFamily: 'Serif',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.book.author,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: AppTheme.getTextSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.book.wordCount > 0) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${widget.book.wordCount} ${widget.book.wordCount == 1 ? 'word' : 'words'}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Delete button
                        _DeleteButton(
                          onTap: () async {
                            setState(() => _isDeleting = true);
                            await Future.delayed(AppTheme.sheetAnimDuration);
                            widget.onDelete();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.menu_book_outlined,
        size: 24,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
  }
}

/// Delete button with ripple effect
class _DeleteButton extends StatefulWidget {
  final VoidCallback onTap;

  const _DeleteButton({required this.onTap});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
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
                    ? AppTheme.error.withValues(alpha: 0.1)
                    : Colors.transparent,
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            size: 22,
            color: AppTheme.getTextMuted(context),
          ),
        ),
      ),
    );
  }
}
