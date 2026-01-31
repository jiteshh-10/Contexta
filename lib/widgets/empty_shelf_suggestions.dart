import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/book_suggestion.dart';
import 'primary_button.dart';

/// Empty shelf state for book suggestions
///
/// Displays when user has no books on shelf.
/// Philosophy: Explain absence, invite gently, never pressure.
class EmptyShelfSuggestions extends StatefulWidget {
  final VoidCallback onAddBook;
  final bool showTimelessSuggestions;

  const EmptyShelfSuggestions({
    super.key,
    required this.onAddBook,
    this.showTimelessSuggestions = true,
  });

  @override
  State<EmptyShelfSuggestions> createState() => _EmptyShelfSuggestionsState();
}

class _EmptyShelfSuggestionsState extends State<EmptyShelfSuggestions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Decorative book icon
            _buildBookIcon(context),

            const SizedBox(height: 24),

            // Header - italic, muted, calm
            Text(
              'Every reading journey starts somewhere.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                color: AppTheme.getTextSecondary(context),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Body copy - explanatory, non-judgmental
            Text(
              'Add your first book to Contexta, and this space will begin offering thoughtful suggestions shaped by how you read.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.getTextMuted(context),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 28),

            // Primary action
            PrimaryButton(
              label: 'Add your first book',
              icon: Icons.auto_stories_outlined,
              onPressed: widget.onAddBook,
            ),

            // Optional timeless suggestions
            if (widget.showTimelessSuggestions) ...[
              const SizedBox(height: 32),
              _buildTimelessSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookIcon(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            AppTheme.isDark(context)
                ? AppTheme.darkPaperHighest
                : AppTheme.beigeDarker.withValues(alpha: 0.5),
      ),
      child: Icon(
        Icons.auto_stories_outlined,
        size: 28,
        color: AppTheme.getTextMuted(context),
      ),
    );
  }

  Widget _buildTimelessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Container(height: 1, color: AppTheme.getBorder(context)),

        const SizedBox(height: 24),

        // Section header - subtle, not pushing
        Text(
          'Often chosen as a starting point',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: AppTheme.getTextMuted(context),
          ),
        ),

        const SizedBox(height: 16),

        // Timeless classics - simple list, no interaction required
        ...TimelessSuggestions.classics.map(
          (book) => _TimelessBookItem(suggestion: book),
        ),
      ],
    );
  }
}

/// Simple display of a timeless book suggestion
/// No actions, just information
class _TimelessBookItem extends StatelessWidget {
  final BookSuggestion suggestion;

  const _TimelessBookItem({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book spine indicator
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color:
                  AppTheme.isDark(context)
                      ? AppTheme.darkInkBlue.withValues(alpha: 0.4)
                      : AppTheme.inkBlue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),

          // Book info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and author
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: suggestion.title,
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      TextSpan(
                        text: ' — ',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 14,
                          color: AppTheme.getTextMuted(context),
                        ),
                      ),
                      TextSpan(
                        text: suggestion.author,
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Reason - italic, muted
                Text(
                  suggestion.reason,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.getTextMuted(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
