import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

/// Export options bottom sheet with smooth animations
/// Features: Format selection, scope selection (for library), preview, share
class ExportOptionsSheet extends StatefulWidget {
  final Book? book;
  final List<Book>? books;
  final VoidCallback onClose;

  const ExportOptionsSheet({
    super.key,
    this.book,
    this.books,
    required this.onClose,
  }) : assert(
         book != null || books != null,
         'Either book or books must be provided',
       );

  @override
  State<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends State<ExportOptionsSheet>
    with TickerProviderStateMixin {
  final ExportService _exportService = ExportService();

  ExportFormat _selectedFormat = ExportFormat.markdown;
  bool _isExporting = false;
  bool _showPreview = false;

  late final AnimationController _formatController;
  late final AnimationController _previewController;

  @override
  void initState() {
    super.initState();
    _formatController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _previewController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _formatController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  int get _wordCount {
    if (widget.book != null) {
      return widget.book!.wordCount;
    }
    return widget.books?.fold<int>(0, (sum, b) => sum + b.wordCount) ?? 0;
  }

  int get _bookCount {
    if (widget.book != null) return 1;
    return widget.books?.where((b) => b.hasWords).length ?? 0;
  }

  String get _exportTitle {
    if (widget.book != null) {
      return 'Export "${widget.book!.title}"';
    }
    return 'Export All Words';
  }

  void _togglePreview() {
    setState(() => _showPreview = !_showPreview);
    if (_showPreview) {
      _previewController.forward();
    } else {
      _previewController.reverse();
    }
    HapticFeedback.selectionClick();
  }

  Future<void> _handleExport() async {
    if (_wordCount == 0) {
      _showError('No words to export');
      return;
    }

    setState(() => _isExporting = true);
    HapticFeedback.lightImpact();

    final result = await _exportService.exportAndShare(
      format: _selectedFormat,
      book: widget.book,
      books: widget.books,
    );

    if (!mounted) return;

    setState(() => _isExporting = false);

    if (result.success) {
      HapticFeedback.mediumImpact();
      widget.onClose();
      _showSuccess('Exported ${result.wordCount} words');
    } else {
      HapticFeedback.heavyImpact();
      if (result.error != 'Share was cancelled') {
        _showError(result.error ?? 'Export failed');
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.upload_file_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _exportTitle,
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_wordCount words${_bookCount > 1 ? ' from $_bookCount books' : ''}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              _CloseButton(onTap: widget.onClose),
            ],
          ),

          const SizedBox(height: 24),

          // Format selection
          Text(
            'Format',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextSecondary(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children:
                ExportFormat.values.map((format) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: format != ExportFormat.values.last ? 8 : 0,
                      ),
                      child: _FormatOption(
                        format: format,
                        isSelected: _selectedFormat == format,
                        onTap: () {
                          setState(() => _selectedFormat = format);
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 20),

          // Preview toggle
          GestureDetector(
            onTap: _wordCount > 0 ? _togglePreview : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppTheme.darkPaperElevated
                        : AppTheme.beigeDarker.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _showPreview
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3)
                          : AppTheme.getBorder(context),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color:
                        _showPreview
                            ? Theme.of(context).colorScheme.primary
                            : AppTheme.getTextMuted(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Preview export',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color:
                            _showPreview
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showPreview ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: AppTheme.getTextMuted(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Preview content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child:
                _showPreview
                    ? FadeTransition(
                      opacity: _previewController,
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(16),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppTheme.darkBackground : AppTheme.beige,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.getBorder(context),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _exportService.previewContent(
                              format: _selectedFormat,
                              book: widget.book,
                              books: widget.books,
                              maxLines: 25,
                            ),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              height: 1.4,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Export button
          _ExportButton(
            onTap: _handleExport,
            isLoading: _isExporting,
            disabled: _wordCount == 0,
            format: _selectedFormat,
          ),
        ],
      ),
    );
  }
}

/// Format selection option
class _FormatOption extends StatefulWidget {
  final ExportFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FormatOption> createState() => _FormatOptionState();
}

class _FormatOptionState extends State<_FormatOption> {
  bool _isPressed = false;

  IconData get _icon {
    switch (widget.format) {
      case ExportFormat.plainText:
        return Icons.description_outlined;
      case ExportFormat.markdown:
        return Icons.code_rounded;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.96 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color:
                widget.isSelected
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1)
                    : isDark
                    ? AppTheme.darkPaperElevated
                    : AppTheme.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  widget.isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.getBorder(context),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow:
                widget.isSelected
                    ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Column(
            children: [
              Icon(
                _icon,
                size: 22,
                color:
                    widget.isSelected
                        ? Theme.of(context).colorScheme.primary
                        : AppTheme.getTextMuted(context),
              ),
              const SizedBox(height: 6),
              Text(
                widget.format.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      widget.isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '.${widget.format.extension}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppTheme.getTextMuted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Export action button
class _ExportButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final bool disabled;
  final ExportFormat format;

  const _ExportButton({
    required this.onTap,
    required this.isLoading,
    required this.disabled,
    required this.format,
  });

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final canTap = !widget.disabled && !widget.isLoading;

    return GestureDetector(
      onTapDown: canTap ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: canTap ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: canTap ? () => setState(() => _isPressed = false) : null,
      onTap: canTap ? widget.onTap : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.97 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: widget.disabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.share_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ],
                const SizedBox(width: 12),
                Text(
                  widget.isLoading
                      ? 'Preparing...'
                      : 'Share as ${widget.format.label}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

/// Close button
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
