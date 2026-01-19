import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/word_entry.dart';
import '../theme/app_theme.dart';
import 'secondary_button.dart';
import 'contexta_text_field.dart';
import 'loading_dots.dart';

/// Word explanation bottom sheet with full details
/// Features: Haptic feedback on delete, edit mode with refetch, formatted explanation
class WordExplanationSheet extends StatefulWidget {
  final WordEntry entry;
  final String bookTitle;
  final String bookAuthor;
  final VoidCallback onClose;
  final VoidCallback onRemove;
  final void Function(WordEntry)? onUpdate;
  final Future<String?> Function(String word)? onRefetchExplanation;

  const WordExplanationSheet({
    super.key,
    required this.entry,
    required this.bookTitle,
    required this.bookAuthor,
    required this.onClose,
    required this.onRemove,
    this.onUpdate,
    this.onRefetchExplanation,
  });

  @override
  State<WordExplanationSheet> createState() => _WordExplanationSheetState();
}

class _WordExplanationSheetState extends State<WordExplanationSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  bool _isRemoving = false;
  bool _isEditing = false;
  bool _isRefetching = false;
  late String _editedWord;

  @override
  void initState() {
    super.initState();
    _editedWord = widget.entry.word;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRemove() async {
    // Trigger haptic feedback
    HapticFeedback.mediumImpact();

    setState(() => _isRemoving = true);

    // Start fade-out animation
    await _animController.forward();

    // Call the remove callback
    widget.onRemove();
    widget.onClose();
  }

  Future<void> _handleSaveEdit() async {
    final newWord = _editedWord.trim();
    if (newWord.isEmpty) return;

    // Check if word changed
    if (newWord.toLowerCase() != widget.entry.word.toLowerCase()) {
      // Word changed - refetch explanation
      if (widget.onRefetchExplanation != null) {
        setState(() => _isRefetching = true);
        HapticFeedback.lightImpact();

        final newExplanation = await widget.onRefetchExplanation!(newWord);

        if (!mounted) return;

        if (newExplanation != null) {
          final updatedEntry = widget.entry.copyWith(
            word: newWord,
            explanation: newExplanation,
          );
          widget.onUpdate?.call(updatedEntry);
          setState(() {
            _isEditing = false;
            _isRefetching = false;
          });
          HapticFeedback.mediumImpact();
        } else {
          // Failed to refetch - show error
          setState(() => _isRefetching = false);
          HapticFeedback.heavyImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to get new explanation'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
            );
          }
        }
      }
    } else {
      // Word not changed - just close edit mode
      setState(() => _isEditing = false);
    }
  }

  void _handleCancelEdit() {
    setState(() {
      _isEditing = false;
      _editedWord = widget.entry.word;
    });
  }

  /// Parse explanation to extract short definition and context
  Map<String, String> _parseExplanation(String explanation) {
    // Clean up any markdown formatting
    String cleaned =
        explanation
            .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1') // Remove **bold**
            .replaceAll(RegExp(r'\*(.+?)\*'), r'$1') // Remove *italic*
            .replaceAll(RegExp(r'__(.+?)__'), r'$1') // Remove __bold__
            .replaceAll(RegExp(r'_(.+?)_'), r'$1') // Remove _italic_
            .replaceAll(
              RegExp(r'\[([^\]]+)\]\([^)]+\)'),
              r'$1',
            ) // Remove [text](link)
            .trim();

    // Try to split by separator line (---)
    if (cleaned.contains('---')) {
      final parts = cleaned.split('---');
      if (parts.length >= 2) {
        final shortDef = parts[0].trim();
        final context = parts.sublist(1).join(' ').trim();
        return {'short': shortDef, 'context': context};
      }
    }

    // Fallback: Try to extract bold pattern (from old format)
    final boldPattern = RegExp(r'\*\*(.+?)\*\*');
    final match = boldPattern.firstMatch(explanation);

    if (match != null) {
      final shortDef = match.group(1) ?? '';
      final context =
          explanation
              .replaceFirst(boldPattern, '')
              .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
              .trim();
      return {'short': shortDef, 'context': context};
    }

    // Fallback: use first sentence as short definition
    final sentences = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.length > 1) {
      return {'short': sentences.first, 'context': sentences.skip(1).join(' ')};
    }

    return {'short': '', 'context': cleaned};
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseExplanation(widget.entry.explanation);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_CloseButton(onTap: widget.onClose)],
            ),

            const SizedBox(height: 8),

            // Word display or edit
            if (_isEditing) ...[
              ContextaTextField(
                label: 'Word',
                placeholder: 'Enter word',
                value: _editedWord,
                onChanged: (v) => setState(() => _editedWord = v),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              if (_isRefetching) ...[
                const SizedBox(height: 24),
                const LoadingDots(),
                const SizedBox(height: 8),
                Text(
                  'Getting new explanation...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ] else ...[
              // Word title
              Text(
                widget.entry.capitalizedWord,
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Short definition (if available)
              if (parsed['short']!.isNotEmpty) ...[
                Text(
                  parsed['short']!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Contextual explanation
              if (parsed['context']!.isNotEmpty)
                Text(
                  parsed['context']!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    height: 1.6,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
            ],

            const SizedBox(height: 24),

            // Divider
            Container(height: 1, color: AppTheme.getBorder(context)),

            const SizedBox(height: 16),

            // Book reference
            Text(
              '${widget.bookTitle} · ${widget.bookAuthor}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      onPressed: _handleCancelEdit,
                      disabled: _isRefetching,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SaveButton(
                      onTap: _handleSaveEdit,
                      disabled: _editedWord.trim().isEmpty || _isRefetching,
                      isLoading: _isRefetching,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  // Edit button
                  if (widget.onUpdate != null)
                    Expanded(
                      child: SecondaryButton(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                    ),

                  if (widget.onUpdate != null) const SizedBox(width: 12),

                  // Remove button
                  Expanded(
                    child: SecondaryButton(
                      label: 'Remove',
                      icon: Icons.delete_outline_rounded,
                      destructive: true,
                      disabled: _isRemoving,
                      onPressed: _handleRemove,
                    ),
                  ),
                ],
              ),
            ],
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _isPressed ? AppTheme.getBorder(context) : Colors.transparent,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 22,
            color: AppTheme.getTextMuted(context),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool disabled;
  final bool isLoading;

  const _SaveButton({
    required this.onTap,
    this.disabled = false,
    this.isLoading = false,
  });

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.disabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp:
          widget.disabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel:
          widget.disabled ? null : () => setState(() => _isPressed = false),
      onTap: widget.disabled ? null : widget.onTap,
      child: AnimatedScale(
        duration: AppTheme.buttonPressDuration,
        scale: _isPressed ? 0.97 : 1.0,
        child: AnimatedOpacity(
          duration: AppTheme.buttonPressDuration,
          opacity: widget.disabled ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                else
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                const SizedBox(width: 8),
                Text(
                  widget.isLoading ? 'Saving...' : 'Save',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimary,
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
