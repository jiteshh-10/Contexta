import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Show a dialog with Contexta styling
/// Features: Scale-in animation (200ms), rounded corners, action buttons
Future<T?> showContextaDialog<T>({
  required BuildContext context,
  String? title,
  required Widget content,
  List<Widget>? actions,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: AppTheme.dialogAnimDuration,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: _DialogContent(
            title: title,
            content: content,
            actions: actions,
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scaleAnimation = Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(scale: scaleAnimation, child: child),
      );
    },
  );
}

class _DialogContent extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;

  const _DialogContent({this.title, required this.content, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 350, minWidth: 280),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                title!,
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              title != null ? 16 : 24,
              24,
              actions != null ? 16 : 24,
            ),
            child: content,
          ),

          // Actions
          if (actions != null && actions!.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children:
                    actions!.map((action) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: action,
                        ),
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// A simple confirmation dialog that returns true/false
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final result = await showContextaDialog<bool>(
    context: context,
    title: title,
    content: Text(
      message,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        color: AppTheme.getTextSecondary(context),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    ),
    actions: [
      _DialogButton(
        label: cancelLabel,
        isPrimary: false,
        onTap: () => Navigator.of(context).pop(false),
      ),
      _DialogButton(
        label: confirmLabel,
        isPrimary: true,
        isDestructive: isDestructive,
        onTap: () => Navigator.of(context).pop(true),
      ),
    ],
  );
  return result ?? false;
}

class _DialogButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.isPrimary,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _isPressed = false;

  Color _getButtonColor(BuildContext context) {
    if (widget.isDestructive) {
      return AppTheme.isDark(context) ? AppTheme.darkError : AppTheme.error;
    }
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = _getButtonColor(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: AppTheme.buttonPressDuration,
        scale: _isPressed ? 0.97 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.isPrimary ? buttonColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border:
                widget.isPrimary
                    ? null
                    : Border.all(color: buttonColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  widget.isPrimary
                      ? Theme.of(context).colorScheme.onPrimary
                      : buttonColor,
            ),
          ),
        ),
      ),
    );
  }
}
