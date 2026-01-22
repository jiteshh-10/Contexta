import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Show a modal bottom sheet with Contexta styling
/// Features: 200ms slide animation, drag handle, max height 85vh, rounded top corners
Future<T?> showContextaBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showCloseButton = false,
  VoidCallback? onClose,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: AppTheme.sheetAnimDuration,
    ),
    builder:
        (context) => _BottomSheetContent(
          showCloseButton: showCloseButton,
          onClose: onClose,
          child: child,
        ),
  );
}

class _BottomSheetContent extends StatelessWidget {
  final Widget child;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const _BottomSheetContent({
    required this.child,
    this.showCloseButton = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusSheet),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with drag handle and optional close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.getBorder(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Close button
                  if (showCloseButton)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _CloseButton(
                        onTap: () {
                          onClose?.call();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: AppTheme.buttonPressDuration,
        scale: _isPressed ? 0.9 : 1.0,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _isPressed ? AppTheme.getBorder(context) : Colors.transparent,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: AppTheme.getTextMuted(context),
          ),
        ),
      ),
    );
  }
}
