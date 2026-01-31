import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A gentle suggestion strip that appears below input fields
/// Shows max 3 suggestions with subtle fade+slide animation
/// Designed for literary apps - no dropdown spam, no aggressive autocomplete
class SuggestionStrip extends StatefulWidget {
  final List<String> suggestions;
  final void Function(String) onSelect;
  final bool isVisible;

  const SuggestionStrip({
    super.key,
    required this.suggestions,
    required this.onSelect,
    this.isVisible = true,
  });

  @override
  State<SuggestionStrip> createState() => _SuggestionStripState();
}

class _SuggestionStripState extends State<SuggestionStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isVisible && widget.suggestions.isNotEmpty) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SuggestionStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldShow = widget.isVisible && widget.suggestions.isNotEmpty;
    final wasShowing = oldWidget.isVisible && oldWidget.suggestions.isNotEmpty;

    if (shouldShow && !wasShowing) {
      _controller.forward();
    } else if (!shouldShow && wasShowing) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = AppTheme.isDark(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkPaper : AppTheme.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.border,
              width: 1,
            ),
            boxShadow:
                isDark
                    ? []
                    : [
                      BoxShadow(
                        color: AppTheme.charcoal.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < widget.suggestions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  ),
                _SuggestionItem(
                  suggestion: widget.suggestions[i],
                  onTap: () => widget.onSelect(widget.suggestions[i]),
                  isFirst: i == 0,
                  isLast: i == widget.suggestions.length - 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual suggestion item with hover/tap states
class _SuggestionItem extends StatefulWidget {
  final String suggestion;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _SuggestionItem({
    required this.suggestion,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_SuggestionItem> createState() => _SuggestionItemState();
}

class _SuggestionItemState extends State<_SuggestionItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                _isPressed
                    ? (isDark ? AppTheme.darkBorder : AppTheme.beigeDarker)
                    : (_isHovered
                        ? (isDark
                            ? AppTheme.darkBorder.withValues(alpha: 0.5)
                            : AppTheme.beige)
                        : Colors.transparent),
            borderRadius: BorderRadius.vertical(
              top: widget.isFirst ? const Radius.circular(11) : Radius.zero,
              bottom: widget.isLast ? const Radius.circular(11) : Radius.zero,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.suggestion,
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color:
                        _isHovered || _isPressed
                            ? (isDark ? AppTheme.darkInkBlue : AppTheme.inkBlue)
                            : AppTheme.getTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
