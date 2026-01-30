import 'package:flutter/material.dart';
import '../models/difficulty_reason.dart';
import '../theme/app_theme.dart';

/// DifficultyReasonSelector widget
/// A subtle, skippable selector for tagging why a word was difficult
/// Features a poppy animation when chips appear and are selected
class DifficultyReasonSelector extends StatefulWidget {
  final DifficultyReason? selectedReason;
  final ValueChanged<DifficultyReason?> onReasonChanged;
  final VoidCallback? onSkip;
  final bool showHeader;

  const DifficultyReasonSelector({
    super.key,
    this.selectedReason,
    required this.onReasonChanged,
    this.onSkip,
    this.showHeader = true,
  });

  @override
  State<DifficultyReasonSelector> createState() =>
      _DifficultyReasonSelectorState();
}

class _DifficultyReasonSelectorState extends State<DifficultyReasonSelector>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _bounceController;
  late final List<Animation<double>> _chipAnimations;

  DifficultyReason? _lastSelected;

  @override
  void initState() {
    super.initState();

    // Entrance animation for chips appearing
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Bounce animation for selection feedback
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Staggered animations for each chip
    _chipAnimations = List.generate(DifficultyReason.values.length, (index) {
      final startDelay = index * 0.15;
      final endPoint = startDelay + 0.6;
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(
          startDelay.clamp(0.0, 1.0),
          endPoint.clamp(0.0, 1.0),
          curve: Curves.elasticOut,
        ),
      );
    });

    // Start entrance animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleSelection(DifficultyReason reason) {
    _lastSelected = reason;
    _bounceController.forward(from: 0);

    if (widget.selectedReason == reason) {
      // Deselect if tapping the same reason
      widget.onReasonChanged(null);
    } else {
      widget.onReasonChanged(reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showHeader) ...[
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Why was this tricky?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              if (widget.onSkip != null)
                GestureDetector(
                  onTap: widget.onSkip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Chips in a wrap layout
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            DifficultyReason.values.length,
            (index) => _buildReasonChip(
              DifficultyReason.values[index],
              _chipAnimations[index],
              isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonChip(
    DifficultyReason reason,
    Animation<double> entranceAnim,
    bool isDark,
  ) {
    final isSelected = widget.selectedReason == reason;
    final wasJustSelected = _lastSelected == reason;

    return AnimatedBuilder(
      animation: Listenable.merge([entranceAnim, _bounceController]),
      builder: (context, child) {
        // Entrance scale from elastic curve
        final entranceScale = entranceAnim.value;

        // Bounce effect when selected
        double bounceScale = 1.0;
        if (wasJustSelected && _bounceController.isAnimating) {
          final bounceValue = _bounceController.value;
          // Quick pop up then settle
          if (bounceValue < 0.3) {
            bounceScale = 1.0 + (bounceValue / 0.3) * 0.1;
          } else {
            bounceScale = 1.1 - ((bounceValue - 0.3) / 0.7) * 0.1;
          }
        }

        return Transform.scale(
          scale: entranceScale * bounceScale,
          child: Opacity(opacity: entranceScale.clamp(0.0, 1.0), child: child),
        );
      },
      child: _DifficultyChip(
        reason: reason,
        isSelected: isSelected,
        isDark: isDark,
        onTap: () => _handleSelection(reason),
      ),
    );
  }
}

/// Individual difficulty reason chip with selection state
class _DifficultyChip extends StatefulWidget {
  final DifficultyReason reason;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _DifficultyChip({
    required this.reason,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_DifficultyChip> createState() => _DifficultyChipState();
}

class _DifficultyChipState extends State<_DifficultyChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final reasonColor = widget.reason.color;

    // Adaptive colors based on selection and theme
    final backgroundColor =
        widget.isSelected
            ? reasonColor.withValues(alpha: widget.isDark ? 0.25 : 0.15)
            : widget.isDark
            ? AppTheme.darkPaperElevated
            : AppTheme.beigeDarker.withValues(alpha: 0.5);

    final borderColor =
        widget.isSelected
            ? reasonColor.withValues(alpha: 0.6)
            : widget.isDark
            ? AppTheme.darkBorder
            : AppTheme.border;

    final textColor =
        widget.isSelected
            ? reasonColor
            : widget.isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.textSecondary;

    final iconColor =
        widget.isSelected
            ? reasonColor
            : widget.isDark
            ? AppTheme.darkTextMuted
            : AppTheme.textMuted;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_pressController.value * 0.05),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow:
                widget.isSelected && !widget.isDark
                    ? [
                      BoxShadow(
                        color: reasonColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.reason.icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                widget.reason.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                  letterSpacing: 0.1,
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_rounded, size: 14, color: reasonColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact inline display of a difficulty reason (for word list items)
class DifficultyReasonBadge extends StatelessWidget {
  final DifficultyReason reason;
  final bool compact;

  const DifficultyReasonBadge({
    super.key,
    required this.reason,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = reason.color.withValues(alpha: isDark ? 0.2 : 0.12);
    final textColor = reason.color;

    if (compact) {
      // Icon only for compact display
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(reason.icon, size: 12, color: textColor),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(reason.icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            reason.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
