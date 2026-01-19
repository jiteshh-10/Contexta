import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated loading dots with "Finding meaning in context…" text
/// Features: Staggered bounce animation, 1.4s cycle, 150ms delay between dots
class LoadingDots extends StatefulWidget {
  final String? message;

  const LoadingDots({super.key, this.message});

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
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message ?? 'Finding meaning in context',
            style: TextStyle(
              fontFamily: 'Inter',
              fontStyle: FontStyle.italic,
              fontSize: 14,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) => _buildDot(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate staggered animation with 150ms offset between dots
        // Each dot takes 0.4 of the cycle to complete its bounce
        final delay = index * 0.15; // 150ms delay between dots
        final animValue = (_controller.value + delay) % 1.0;

        // Bounce animation: scale up for first half, scale down for second half
        double scale;
        if (animValue < 0.2) {
          // Rising
          scale = 1.0 + (animValue / 0.2) * 0.3;
        } else if (animValue < 0.4) {
          // Falling
          scale = 1.3 - ((animValue - 0.2) / 0.2) * 0.3;
        } else {
          // Resting
          scale = 1.0;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 6,
              height: 6,
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
