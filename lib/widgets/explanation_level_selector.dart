import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/explanation_level.dart';
import '../theme/app_theme.dart';

/// A beautiful animated segmented control for selecting explanation levels
///
/// Features:
/// - Smooth sliding indicator animation
/// - Haptic feedback on selection
/// - Accessibility support
/// - Consistent with app design language
class ExplanationLevelSelector extends StatefulWidget {
  final ExplanationLevel selectedLevel;
  final ValueChanged<ExplanationLevel> onLevelChanged;
  final bool enabled;

  const ExplanationLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
    this.enabled = true,
  });

  @override
  State<ExplanationLevelSelector> createState() =>
      _ExplanationLevelSelectorState();
}

class _ExplanationLevelSelectorState extends State<ExplanationLevelSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  int _previousIndex = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedLevel.index;
    _previousIndex = _currentIndex;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.value = 1.0;
  }

  @override
  void didUpdateWidget(ExplanationLevelSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLevel != widget.selectedLevel) {
      _animateToIndex(widget.selectedLevel.index);
    }
  }

  void _animateToIndex(int newIndex) {
    _previousIndex = _currentIndex;
    _currentIndex = newIndex;
    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap(ExplanationLevel level) {
    if (!widget.enabled || level == widget.selectedLevel) return;

    HapticFeedback.selectionClick();
    widget.onLevelChanged(level);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark
            ? AppTheme.darkPaper
            : AppTheme.beigeDarker.withValues(alpha: 0.5);

    final indicatorColor = isDark ? AppTheme.darkPaperElevated : Colors.white;

    final selectedTextColor = theme.colorScheme.primary;
    final unselectedTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return AnimatedOpacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth =
                constraints.maxWidth / ExplanationLevel.values.length;

            return Stack(
              children: [
                // Animated indicator
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    final startPosition = _previousIndex * segmentWidth;
                    final endPosition = _currentIndex * segmentWidth;
                    final currentPosition =
                        startPosition +
                        (endPosition - startPosition) * _slideAnimation.value;

                    return Positioned(
                      left: currentPosition + 3,
                      top: 3,
                      bottom: 3,
                      width: segmentWidth - 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall + 4,
                          ),
                          border:
                              isDark
                                  ? Border.all(
                                    color: AppTheme.darkBorderSubtle,
                                    width: 0.5,
                                  )
                                  : null,
                          boxShadow:
                              isDark
                                  ? [] // No shadow in dark mode
                                  : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                        ),
                      ),
                    );
                  },
                ),

                // Segments
                Row(
                  children:
                      ExplanationLevel.values.map((level) {
                        final isSelected = level == widget.selectedLevel;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onTap(level),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                color:
                                    isSelected
                                        ? selectedTextColor
                                        : unselectedTextColor,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedScale(
                                      scale: isSelected ? 1.1 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Text(
                                        level.icon,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              isSelected
                                                  ? selectedTextColor
                                                  : unselectedTextColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(level.label),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Compact version of the selector for tight spaces
class ExplanationLevelSelectorCompact extends StatelessWidget {
  final ExplanationLevel selectedLevel;
  final ValueChanged<ExplanationLevel> onLevelChanged;
  final bool enabled;

  const ExplanationLevelSelectorCompact({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
    this.enabled = true,
  });

  void _onTap(ExplanationLevel level) {
    if (!enabled || level == selectedLevel) return;
    HapticFeedback.selectionClick();
    onLevelChanged(level);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          ExplanationLevel.values.map((level) {
            final isSelected = level == selectedLevel;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => _onTap(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? theme.colorScheme.primary.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            )
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color:
                          isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isSelected
                              ? theme.colorScheme.primary
                              : (isDark
                                  ? AppTheme.darkTextMuted
                                  : AppTheme.textMuted),
                    ),
                    child: Text(level.label),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
