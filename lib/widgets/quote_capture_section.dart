import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Quote capture section for word explanation sheet
///
/// Allows users to optionally add the sentence where a word appeared.
/// Features:
/// - Collapsed state: Single muted prompt line
/// - Expanded state: Multiline text area with literary styling
/// - Save animation: Subtle highlight fade
/// - Edit mode: Tap quote to edit
class QuoteCaptureSection extends StatefulWidget {
  /// Current quote text (null if none)
  final String? quote;

  /// Whether the section should be in edit mode by default
  final bool startInEditMode;

  /// Called when quote is saved
  final void Function(String? quote) onQuoteChanged;

  /// Whether editing is allowed
  final bool canEdit;

  const QuoteCaptureSection({
    super.key,
    this.quote,
    this.startInEditMode = false,
    required this.onQuoteChanged,
    this.canEdit = true,
  });

  @override
  State<QuoteCaptureSection> createState() => _QuoteCaptureSectionState();
}

class _QuoteCaptureSectionState extends State<QuoteCaptureSection>
    with SingleTickerProviderStateMixin {
  /// Whether the input is expanded/visible
  bool _isExpanded = false;

  /// Whether we're in edit mode (for existing quotes)
  bool _isEditing = false;

  /// Controller for quote input
  late TextEditingController _controller;

  /// Focus node for input
  final FocusNode _focusNode = FocusNode();

  /// Animation controller for expand/collapse
  late AnimationController _animController;

  /// Fade animation
  late Animation<double> _fadeAnimation;

  /// Height animation
  late Animation<double> _heightAnimation;

  /// Animation for save highlight
  bool _showSaveHighlight = false;

  /// Copy variants for the prompt
  static const List<String> _promptVariants = [
    'Add the sentence it appeared in',
    'Remember the line it came from',
    'Save the sentence, if you\'d like',
  ];

  /// Get a consistent prompt based on hashcode
  String get _prompt {
    // Use widget hashcode for consistency
    final index = widget.hashCode.abs() % _promptVariants.length;
    return _promptVariants[index];
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quote ?? '');

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _heightAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    // If we have a quote and should start in edit mode
    if (widget.startInEditMode && widget.quote == null) {
      _isExpanded = true;
      _animController.value = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(QuoteCaptureSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller if quote changed externally
    if (widget.quote != oldWidget.quote && !_isEditing) {
      _controller.text = widget.quote ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// Expand the quote input
  void _expand() {
    if (!widget.canEdit) return;

    setState(() {
      _isExpanded = true;
      _isEditing = widget.quote != null;
    });
    _animController.forward();
    HapticFeedback.selectionClick();

    // Focus after animation
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  /// Collapse the quote input
  void _collapse() {
    _focusNode.unfocus();
    setState(() {
      _isExpanded = false;
      _isEditing = false;
      // Reset to saved quote
      _controller.text = widget.quote ?? '';
    });
    _animController.reverse();
  }

  /// Save the quote
  void _save() {
    final text = _controller.text.trim();
    final newQuote = text.isEmpty ? null : text;

    _focusNode.unfocus();

    // Only trigger animation if quote actually changed
    if (newQuote != widget.quote) {
      widget.onQuoteChanged(newQuote);
      HapticFeedback.lightImpact();

      // Show save highlight animation
      if (newQuote != null) {
        setState(() => _showSaveHighlight = true);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _showSaveHighlight = false);
          }
        });
      }
    }

    setState(() {
      _isExpanded = false;
      _isEditing = false;
    });
    _animController.reverse();
  }

  /// Start editing an existing quote
  void _startEdit() {
    if (!widget.canEdit) return;
    _expand();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuote = widget.quote != null && widget.quote!.trim().isNotEmpty;

    // If we have a quote and not editing, show it
    if (hasQuote && !_isExpanded) {
      return _buildQuoteDisplay();
    }

    // If not expanded and no quote, show prompt
    if (!_isExpanded) {
      return _buildPrompt();
    }

    // Expanded state - show input
    return _buildExpandedInput();
  }

  /// Build the collapsed prompt to add a quote
  Widget _buildPrompt() {
    return GestureDetector(
      onTap: widget.canEdit ? _expand : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _prompt,
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: AppTheme.getTextMuted(context),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Build the display for an existing quote
  Widget _buildQuoteDisplay() {
    return GestureDetector(
      onTap: widget.canEdit ? _startEdit : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:
              _showSaveHighlight
                  ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          '"${widget.quote}"',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 15,
            fontStyle: FontStyle.italic,
            height: 1.6,
            color: AppTheme.getTextSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Build the expanded input state
  Widget _buildExpandedInput() {
    final isDark = AppTheme.isDark(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizeTransition(
        sizeFactor: _heightAnimation,
        axisAlignment: -1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input area
            Container(
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppTheme.darkPaperHighest.withValues(alpha: 0.7)
                        : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.getBorder(context),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 2,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Write the sentence as you remember it…',
                  hintStyle: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.getTextMuted(context),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel button
                GestureDetector(
                  onTap: _collapse,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppTheme.getTextMuted(context),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Save button
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _isEditing ? 'Update' : 'Save',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
