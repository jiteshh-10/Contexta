import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A gentle inline spelling suggestion
/// Shows "Did you mean X?" with subtle animation
/// Never shames the reader - just a quiet whisper of correction
class SpellingSuggestion extends StatefulWidget {
  final String? suggestion;
  final VoidCallback onAccept;
  final bool isVisible;

  const SpellingSuggestion({
    super.key,
    required this.suggestion,
    required this.onAccept,
    this.isVisible = true,
  });

  @override
  State<SpellingSuggestion> createState() => _SpellingSuggestionState();
}

class _SpellingSuggestionState extends State<SpellingSuggestion>
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
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isVisible && widget.suggestion != null) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SpellingSuggestion oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldShow = widget.isVisible && widget.suggestion != null;
    final wasShowing = oldWidget.isVisible && oldWidget.suggestion != null;

    if (shouldShow && !wasShowing) {
      _controller.forward();
    } else if (!shouldShow && wasShowing) {
      _controller.reverse();
    } else if (shouldShow && wasShowing) {
      // Suggestion changed - quick refresh
      if (widget.suggestion != oldWidget.suggestion) {
        _controller.forward(from: 0.5);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestion == null) {
      return const SizedBox.shrink();
    }

    final isDark = AppTheme.isDark(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: GestureDetector(
            onTap: widget.onAccept,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Did you mean ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                _SuggestionWord(word: widget.suggestion!, isDark: isDark),
                Text(
                  '?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: AppTheme.getTextSecondary(context),
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

/// The clickable suggestion word with hover state
class _SuggestionWord extends StatefulWidget {
  final String word;
  final bool isDark;

  const _SuggestionWord({required this.word, required this.isDark});

  @override
  State<_SuggestionWord> createState() => _SuggestionWordState();
}

class _SuggestionWordState extends State<_SuggestionWord> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          widget.word,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: widget.isDark ? AppTheme.darkInkBlue : AppTheme.inkBlue,
            decoration: _isHovered ? TextDecoration.underline : null,
            decorationColor:
                widget.isDark ? AppTheme.darkInkBlue : AppTheme.inkBlue,
          ),
        ),
      ),
    );
  }
}
