import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Secondary action button with transparent background
/// Features: Press animation (scale 0.97), hover overlay, optional icon
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool fullWidth;
  final bool disabled;
  final IconData? icon;
  final Color? textColor;
  final bool destructive;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = false,
    this.disabled = false,
    this.icon,
    this.textColor,
    this.destructive = false,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.disabled) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  Color _getTextColor(BuildContext context) {
    if (widget.textColor != null) return widget.textColor!;
    if (widget.destructive) {
      return AppTheme.isDark(context) ? AppTheme.darkError : AppTheme.error;
    }
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor(context);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.disabled ? null : widget.onPressed,
      child: AnimatedScale(
        duration: AppTheme.buttonPressDuration,
        scale: _isPressed ? AppTheme.buttonPressedScale : 1.0,
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: AppTheme.buttonPressDuration,
          opacity: widget.disabled ? 0.4 : 1.0,
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            decoration: BoxDecoration(
              color:
                  _isPressed
                      ? textColor.withValues(alpha: 0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              border: Border.all(
                color: textColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize:
                  widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: textColor),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
