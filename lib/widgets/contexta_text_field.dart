import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom text field with bookish styling
/// Features: Focus ring, error state, italic placeholder, proper accessibility
class ContextaTextField extends StatefulWidget {
  final String? label;
  final String placeholder;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final bool disabled;
  final String? error;
  final int maxLines;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;

  const ContextaTextField({
    super.key,
    this.label,
    required this.placeholder,
    required this.value,
    required this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.disabled = false,
    this.error,
    this.maxLines = 1,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.focusNode,
  });

  @override
  State<ContextaTextField> createState() => _ContextaTextFieldState();
}

class _ContextaTextFieldState extends State<ContextaTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(ContextaTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller if value changed externally
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: widget.value.length,
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  hasError
                      ? Theme.of(context).colorScheme.error
                      : AppTheme.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Text field with animated border
        AnimatedContainer(
          duration: AppTheme.cardPressDuration,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow:
                _hasFocus && !hasError
                    ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                    : null,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !widget.disabled,
            autofocus: widget.autofocus,
            maxLines: widget.maxLines,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            onChanged: widget.onChanged,
            onSubmitted:
                widget.onSubmitted != null
                    ? (_) => widget.onSubmitted!()
                    : null,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppTheme.getTextMuted(context),
              ),
              errorText: hasError ? widget.error : null,
              filled: true,
              fillColor:
                  widget.disabled
                      ? Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: AppTheme.getBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: AppTheme.getBorder(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(
                  color: AppTheme.getBorder(context).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
