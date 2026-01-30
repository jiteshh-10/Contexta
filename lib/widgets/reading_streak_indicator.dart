import 'dart:async';
import 'package:flutter/material.dart';
import '../services/reading_streak_service.dart';
import '../theme/app_theme.dart';

/// Subtle reading consistency indicator widget
///
/// Displays reading streak data in a minimal, non-pressuring way.
/// Features:
/// - Fade-in entry animation
/// - Soft increment animation when new day is added
/// - Optional mini dot row showing recent 7 days
class ReadingStreakIndicator extends StatefulWidget {
  /// Whether to show the mini dot row visualization
  final bool showDotRow;

  const ReadingStreakIndicator({super.key, this.showDotRow = true});

  @override
  State<ReadingStreakIndicator> createState() => _ReadingStreakIndicatorState();
}

class _ReadingStreakIndicatorState extends State<ReadingStreakIndicator>
    with SingleTickerProviderStateMixin {
  final ReadingStreakService _streakService = ReadingStreakService();

  // Animation controllers
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Stream subscription
  StreamSubscription<ReadingStreakData>? _subscription;

  // Current data
  ReadingStreakData? _data;
  bool _isInitialized = false;

  // Increment animation state
  bool _isAnimatingIncrement = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Slide up animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  Future<void> _loadData() async {
    // Load initial data
    final data = await _streakService.getStreakData();

    if (mounted) {
      setState(() {
        _data = data;
        _isInitialized = true;
      });

      // Start entry animation
      _controller.forward();
    }

    // Subscribe to updates
    _subscription = _streakService.streakStream.listen(_handleUpdate);
  }

  void _handleUpdate(ReadingStreakData data) {
    if (!mounted) return;

    // Check if this is a new day being added
    if (data.isNewDayAdded && _data != null) {
      _playIncrementAnimation();
    }

    setState(() {
      _data = data;
    });
  }

  Future<void> _playIncrementAnimation() async {
    if (_isAnimatingIncrement) return;

    setState(() => _isAnimatingIncrement = true);

    // Brief dim
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      setState(() => _isAnimatingIncrement = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _data == null) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isAnimatingIncrement ? 0.6 : 1.0,
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final textColor = AppTheme.getTextSecondary(context).withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main text with bullet - very subtle
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Subtle bullet/star
              Text(
                '✦',
                style: TextStyle(
                  fontSize: 8,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              // Display text - smaller and more muted
              Expanded(
                child: Text(
                  _data!.displayText,
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: textColor,
                    letterSpacing: 0.1,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          // Optional dot row - more subtle
          if (widget.showDotRow && _data!.hasAnyDays) ...[
            const SizedBox(height: 6),
            _DotRow(days: _data!.recentDays),
          ],
        ],
      ),
    );
  }
}

/// Mini dot row showing recent 7 days
class _DotRow extends StatelessWidget {
  final List<ReadingDay> days;

  const _DotRow({required this.days});

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.4);
    final inactiveColor = AppTheme.getTextSecondary(
      context,
    ).withValues(alpha: 0.15);

    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            days.map((day) {
              return Padding(
                padding: const EdgeInsets.only(right: 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: day.isActive ? activeColor : inactiveColor,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
