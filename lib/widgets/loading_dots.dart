import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated loading dots with optional "Finding meaning in context…" text
/// Features: Staggered bounce animation, 1.4s cycle, 150ms delay between dots
///
/// Can be used in two modes:
/// - Full mode (default): Shows text + dots, use in large spaces
/// - Compact mode: Set [compact] to true for dots-only in small spaces
class LoadingDots extends StatefulWidget {
  final String? message;
  final bool compact;
  final double? dotSize;

  const LoadingDots({
    super.key,
    this.message,
    this.compact = false,
    this.dotSize,
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.dotSize ?? (widget.compact ? 4.0 : 6.0);

    // Compact mode: dots only, centered
    if (widget.compact) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) => _buildDot(index, dotSize)),
        ),
      );
    }

    // Full mode: text + dots
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.message ?? 'Finding meaning in context',
              style: TextStyle(
                fontFamily: 'Inter',
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) => _buildDot(index, dotSize)),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, double dotSize) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate staggered animation with 150ms offset between dots
        final delay = index * 0.15;
        final animValue = (_controller.value + delay) % 1.0;

        // Bounce animation
        double scale;
        if (animValue < 0.2) {
          scale = 1.0 + (animValue / 0.2) * 0.3;
        } else if (animValue < 0.4) {
          scale = 1.3 - ((animValue - 0.2) / 0.2) * 0.3;
        } else {
          scale = 1.0;
        }

        final margin = widget.compact ? 1.5 : 2.0;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: margin),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
