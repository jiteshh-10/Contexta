import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/book_suggestion.dart';

/// Displays book suggestions with staggered fade-in animation
///
/// Philosophy:
/// - Max 3 suggestions at a time
/// - Each includes title, author, and reason
/// - Actions: Add to Shelf, Dismiss
/// - Feels like "ideas surfacing", not "cards competing"
class SuggestionsList extends StatefulWidget {
  final List<BookSuggestion> suggestions;
  final void Function(BookSuggestion suggestion) onAddToShelf;
  final void Function(BookSuggestion suggestion) onDismiss;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  const SuggestionsList({
    super.key,
    required this.suggestions,
    required this.onAddToShelf,
    required this.onDismiss,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  @override
  State<SuggestionsList> createState() => _SuggestionsListState();
}

class _SuggestionsListState extends State<SuggestionsList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.suggestions.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );

    _fadeAnimations =
        _controllers.map((controller) {
          return CurvedAnimation(parent: controller, curve: Curves.easeOut);
        }).toList();

    // Staggered animation start (60-80ms gap)
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + (i * 70)), () {
        if (mounted && i < _controllers.length) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(SuggestionsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suggestions.length != oldWidget.suggestions.length) {
      _disposeAnimations();
      _initAnimations();
    }
  }

  void _disposeAnimations() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Based on your reading…',
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: AppTheme.getTextMuted(context),
            ),
          ),

          const SizedBox(height: 20),

          // Content based on state
          if (widget.isLoading)
            _buildLoadingState(context)
          else if (widget.error != null)
            _buildErrorState(context)
          else if (widget.suggestions.isEmpty)
            _buildEmptyState(context)
          else
            _buildSuggestionsList(context),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.getTextMuted(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Finding thoughtful suggestions…',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppTheme.getTextMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 32,
              color: AppTheme.getTextMuted(context),
            ),
            const SizedBox(height: 12),
            Text(
              widget.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: widget.onRetry,
                child: Text(
                  'Try again',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        AppTheme.isDark(context)
                            ? AppTheme.darkInkBlue
                            : AppTheme.inkBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No suggestions available right now.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: AppTheme.getTextMuted(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context) {
    return Column(
      children: List.generate(widget.suggestions.length, (index) {
        final suggestion = widget.suggestions[index];
        return FadeTransition(
          opacity:
              index < _fadeAnimations.length
                  ? _fadeAnimations[index]
                  : const AlwaysStoppedAnimation(1.0),
          child: _SuggestionCard(
            suggestion: suggestion,
            onAddToShelf: () => widget.onAddToShelf(suggestion),
            onDismiss: () => widget.onDismiss(suggestion),
            isLast: index == widget.suggestions.length - 1,
          ),
        );
      }),
    );
  }
}

/// Individual suggestion card with quiet actions
class _SuggestionCard extends StatefulWidget {
  final BookSuggestion suggestion;
  final VoidCallback onAddToShelf;
  final VoidCallback onDismiss;
  final bool isLast;

  const _SuggestionCard({
    required this.suggestion,
    required this.onAddToShelf,
    required this.onDismiss,
    this.isLast = false,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _addPressed = false;
  bool _dismissPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            AppTheme.isDark(context)
                ? AppTheme.darkPaperHighest.withValues(alpha: 0.5)
                : AppTheme.beige,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.getBorder(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and author
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.suggestion.title,
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                TextSpan(
                  text: ' — ',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 16,
                    color: AppTheme.getTextMuted(context),
                  ),
                ),
                TextSpan(
                  text: widget.suggestion.author,
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Reason - the "why"
          Text(
            widget.suggestion.reason,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppTheme.getTextSecondary(context),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 14),

          // Actions - quiet, not competing
          Row(
            children: [
              // Add to Shelf - primary action
              _buildAction(
                context: context,
                label: 'Add to Shelf',
                icon: Icons.add_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onAddToShelf();
                },
                isPressed: _addPressed,
                onPressChange:
                    (pressed) => setState(() => _addPressed = pressed),
                isPrimary: true,
              ),

              const SizedBox(width: 12),

              // Dismiss - secondary action
              _buildAction(
                context: context,
                label: 'Dismiss',
                icon: Icons.close_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onDismiss();
                },
                isPressed: _dismissPressed,
                onPressChange:
                    (pressed) => setState(() => _dismissPressed = pressed),
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAction({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPressed,
    required void Function(bool) onPressChange,
    required bool isPrimary,
  }) {
    final color =
        isPrimary
            ? (AppTheme.isDark(context)
                ? AppTheme.darkInkBlue
                : AppTheme.inkBlue)
            : AppTheme.getTextMuted(context);

    return GestureDetector(
      onTapDown: (_) => onPressChange(true),
      onTapUp: (_) => onPressChange(false),
      onTapCancel: () => onPressChange(false),
      onTap: onTap,
      child: AnimatedScale(
        duration: AppTheme.buttonPressDuration,
        scale: isPressed ? 0.95 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                isPressed ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border:
                isPrimary
                    ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: isPrimary ? FontWeight.w500 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
