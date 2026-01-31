import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Controller for shelf animation state
class ShelfController extends ChangeNotifier {
  bool _isOpen = false;
  bool _isAnimating = false;
  bool _isPlacingBook = false;

  bool get isOpen => _isOpen;
  bool get isAnimating => _isAnimating;
  bool get isPlacingBook => _isPlacingBook;

  void open() {
    if (!_isOpen && !_isAnimating) {
      _isAnimating = true;
      _isOpen = true;
      notifyListeners();
    }
  }

  void close() {
    if (_isOpen && !_isAnimating && !_isPlacingBook) {
      _isAnimating = true;
      _isOpen = false;
      notifyListeners();
    }
  }

  void startPlacingBook() {
    _isPlacingBook = true;
    notifyListeners();
  }

  void finishPlacingBook() {
    _isPlacingBook = false;
    _isOpen = false;
    notifyListeners();
  }

  void onAnimationComplete() {
    _isAnimating = false;
    notifyListeners();
  }
}

/// Shelf overlay that expands to reveal add book content
/// The shelf is a persistent spatial element at the top
class ShelfOverlay extends StatefulWidget {
  final Widget child;
  final ShelfController controller;
  final Widget Function(BuildContext context, VoidCallback onClose)
  addBookBuilder;
  final GlobalKey? bookCardTargetKey;
  final VoidCallback? onPlacementComplete;

  const ShelfOverlay({
    super.key,
    required this.child,
    required this.controller,
    required this.addBookBuilder,
    this.bookCardTargetKey,
    this.onPlacementComplete,
  });

  @override
  State<ShelfOverlay> createState() => ShelfOverlayState();
}

class ShelfOverlayState extends State<ShelfOverlay>
    with TickerProviderStateMixin {
  // Shelf expansion animation
  late AnimationController _shelfController;
  late Animation<double> _shelfExpansion;
  late Animation<double> _contentOpacity;
  late Animation<double> _dimOverlay;

  // Book placement animation
  late AnimationController _bookPlacementController;

  // Cached positions for book animation
  Offset? _bookStartPosition;
  Offset? _bookEndPosition;
  Size? _bookSize;

  // State for showing flying book
  bool _showFlyingBook = false;
  String _flyingBookTitle = '';
  String _flyingBookAuthor = '';

  @override
  void initState() {
    super.initState();

    // Shelf animation - snappy, responsive (160ms for immediacy)
    _shelfController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    _shelfExpansion = CurvedAnimation(
      parent: _shelfController,
      curve: Curves.easeOutCubic,
    );

    // Content fade with minimal delay (starts at 60ms into animation)
    _contentOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 37), // ~60ms delay
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 63,
      ),
    ]).animate(_shelfController);

    // Dim overlay (8% for more visual feedback)
    _dimOverlay = Tween<double>(
      begin: 0.0,
      end: 0.08,
    ).animate(CurvedAnimation(parent: _shelfController, curve: Curves.easeOut));

    // Book placement animation - Apple-style (350ms, quick but smooth)
    _bookPlacementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shelfController.addStatusListener(_onShelfAnimationStatus);
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _shelfController.removeStatusListener(_onShelfAnimationStatus);
    widget.controller.removeListener(_onControllerChange);
    _shelfController.dispose();
    _bookPlacementController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (widget.controller.isOpen && !_shelfController.isCompleted) {
      _shelfController.forward();
    } else if (!widget.controller.isOpen &&
        !widget.controller.isPlacingBook &&
        _shelfController.value > 0) {
      _shelfController.reverse();
    }
  }

  void _onShelfAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      widget.controller.onAnimationComplete();
    }
  }

  /// Called when user wants to place a book on the shelf
  /// Returns the GlobalKey for the preview card to get its position
  void startBookPlacement({
    required String title,
    required String author,
    required Offset startPosition,
    required Size bookSize,
  }) {
    setState(() {
      _flyingBookTitle = title;
      _flyingBookAuthor = author;
      _bookStartPosition = startPosition;
      _bookSize = bookSize;
      _showFlyingBook = true;
    });

    // Calculate end position (first item in list, under app bar)
    // This will be approximately at top of the list area
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    _bookEndPosition = Offset(
      16, // Left padding of list
      appBarHeight + 16, // Just below app bar with padding
    );

    widget.controller.startPlacingBook();

    // Small haptic for intent confirmation
    HapticFeedback.lightImpact();

    // Start the placement animation
    _bookPlacementController.forward(from: 0).then((_) async {
      // Hold for a moment at destination for visual confirmation
      await Future.delayed(const Duration(milliseconds: 80));

      // Tiny settle haptic when book lands
      HapticFeedback.selectionClick();

      setState(() {
        _showFlyingBook = false;
      });

      // Close shelf and notify completion
      widget.controller.finishPlacingBook();
      widget.onPlacementComplete?.call();

      // Animate shelf closing
      _shelfController.reverse();
    });
  }

  void _handleClose() {
    widget.controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content (library)
        widget.child,

        // Dim overlay when shelf is open
        AnimatedBuilder(
          animation: _dimOverlay,
          builder: (context, child) {
            if (_dimOverlay.value == 0) return const SizedBox.shrink();
            return Positioned.fill(
              child: IgnorePointer(
                ignoring: !widget.controller.isOpen,
                child: GestureDetector(
                  onTap: _handleClose,
                  child: Container(
                    color: Colors.black.withValues(alpha: _dimOverlay.value),
                  ),
                ),
              ),
            );
          },
        ),

        // Shelf content (add book panel)
        AnimatedBuilder(
          animation: _shelfExpansion,
          builder: (context, child) {
            if (_shelfExpansion.value == 0) return const SizedBox.shrink();

            final screenHeight = MediaQuery.of(context).size.height;
            final shelfHeight = screenHeight * 0.55; // Expanded shelf height

            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: shelfHeight * _shelfExpansion.value,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _shelfExpansion.value,
                  child: SizedBox(
                    height: shelfHeight,
                    child: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: _contentOpacity.value,
                        child: widget.addBookBuilder(context, _handleClose),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Flying book card during placement animation
        if (_showFlyingBook && _bookStartPosition != null)
          AnimatedBuilder(
            animation: _bookPlacementController,
            builder: (context, child) {
              return _buildFlyingBook();
            },
          ),
      ],
    );
  }

  Widget _buildFlyingBook() {
    if (_bookStartPosition == null || _bookEndPosition == null) {
      return const SizedBox.shrink();
    }

    // Clamp the raw value to prevent floating-point precision errors
    final t = _bookPlacementController.value.clamp(0.0, 1.0);

    // Apple-style curve: fast start, gentle deceleration (like iOS spring)
    final progress = Curves.decelerate.transform(t);

    // Simple linear position interpolation - direct movement
    final currentX =
        _bookStartPosition!.dx +
        (_bookEndPosition!.dx - _bookStartPosition!.dx) * progress;
    final currentY =
        _bookStartPosition!.dy +
        (_bookEndPosition!.dy - _bookStartPosition!.dy) * progress;

    // Apple-style scale with subtle settle bounce at the end
    // Travel at 1.02, then settle with tiny bounce (1.0 → 0.98 → 1.0)
    double scale;
    if (t < 0.85) {
      // Travel phase - slight lift
      scale = 1.0 + (0.02 * (1 - (t / 0.85)));
    } else {
      // Settle phase - tiny bounce (like iOS list insertion)
      final settleT = (t - 0.85) / 0.15;
      // Quick compress then expand: 1.0 → 0.98 → 1.0
      scale = 1.0 - (0.02 * (1 - settleT).abs());
    }

    // Shadow stays subtle throughout, slight increase when landing
    final shadowOpacity = t > 0.85 ? 0.15 : 0.10;

    // Stay fully visible - no fade out, clean handoff to real card
    const opacity = 1.0;

    final isDark = AppTheme.isDark(context);

    return Positioned(
      left: currentX,
      top: currentY,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: _bookSize?.width ?? 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkPaper : AppTheme.paper,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border:
                  isDark
                      ? Border.all(color: AppTheme.darkBorderSubtle, width: 0.5)
                      : null,
              // Apple-style subtle shadow - soft, diffused
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : AppTheme.charcoal).withValues(
                    alpha: shadowOpacity,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _flyingBookTitle,
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_flyingBookAuthor.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'by $_flyingBookAuthor',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 14,
                      color: AppTheme.getTextMuted(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '0 words',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.getTextMuted(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
