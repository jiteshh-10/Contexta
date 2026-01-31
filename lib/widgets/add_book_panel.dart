import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/author_suggestion_service.dart';
import 'contexta_text_field.dart';
import 'primary_button.dart';
import 'suggestion_strip.dart';

/// Add book panel that appears when shelf expands
/// This is not a screen - it's content that lives "under" the shelf
class AddBookPanel extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(
    String title,
    String author,
    Offset cardPosition,
    Size cardSize,
  )
  onPlaceOnShelf;

  const AddBookPanel({
    super.key,
    required this.onClose,
    required this.onPlaceOnShelf,
  });

  @override
  State<AddBookPanel> createState() => AddBookPanelState();
}

class AddBookPanelState extends State<AddBookPanel>
    with SingleTickerProviderStateMixin {
  String _title = '';
  String _author = '';
  String? _titleError;
  bool _isPlacing = false;

  // Author suggestions
  final AuthorSuggestionService _authorService = AuthorSuggestionService();
  List<String> _authorSuggestions = [];
  bool _showAuthorSuggestions = true;

  // Key for the preview card to get its position
  final GlobalKey _previewCardKey = GlobalKey();

  // Animation for preview card appearance
  late AnimationController _previewController;
  late Animation<double> _previewScale;
  late Animation<double> _previewOpacity;

  bool get _canSave => _title.trim().isNotEmpty && !_isPlacing;

  @override
  void initState() {
    super.initState();

    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _previewScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _previewController, curve: Curves.easeOutCubic),
    );

    _previewOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _previewController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  void _handleTitleChange(String value) {
    final wasEmpty = _title.trim().isEmpty;
    final isNowEmpty = value.trim().isEmpty;

    setState(() {
      _title = value;
      if (_titleError != null && value.trim().isNotEmpty) {
        _titleError = null;
      }
    });

    // Animate preview card in/out
    if (wasEmpty && !isNowEmpty) {
      _previewController.forward();
    } else if (!wasEmpty && isNowEmpty) {
      _previewController.reverse();
    }
  }

  void _handleAuthorChange(String value) {
    setState(() => _author = value);
    _updateAuthorSuggestions(value);
  }

  /// Update author suggestions based on current input
  Future<void> _updateAuthorSuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _authorSuggestions = [];
        _showAuthorSuggestions = true;
      });
      return;
    }

    final suggestions = await _authorService.getSuggestions(query);
    if (mounted) {
      setState(() {
        _authorSuggestions = suggestions;
        _showAuthorSuggestions = true;
      });
    }
  }

  /// Handle author suggestion selection
  void _handleAuthorSuggestionSelect(String author) {
    setState(() {
      _author = author;
      _authorSuggestions = [];
      _showAuthorSuggestions = false;
    });
    // Light haptic feedback
    HapticFeedback.selectionClick();
  }

  void _handlePlaceOnShelf() {
    if (!_canSave) return;

    // Validate
    if (_title.trim().isEmpty) {
      setState(() => _titleError = 'Please enter a book title');
      HapticFeedback.lightImpact();
      return;
    }

    // Get the preview card's position
    final RenderBox? cardBox =
        _previewCardKey.currentContext?.findRenderObject() as RenderBox?;

    if (cardBox != null) {
      final position = cardBox.localToGlobal(Offset.zero);
      final size = cardBox.size;

      setState(() => _isPlacing = true);

      // Record author for future suggestions
      if (_author.trim().isNotEmpty) {
        _authorService.recordAuthor(_author.trim());
      }

      // Trigger the placement animation
      widget.onPlaceOnShelf(_title.trim(), _author.trim(), position, size);
    } else {
      // Record author for future suggestions
      if (_author.trim().isNotEmpty) {
        _authorService.recordAuthor(_author.trim());
      }

      // Fallback if we can't get position
      widget.onPlaceOnShelf(
        _title.trim(),
        _author.trim(),
        Offset(16, 200),
        const Size(300, 100),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkPaperElevated : AppTheme.beigeDarker,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: AppTheme.charcoal.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding > 0 ? 8 : 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add a Book',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppTheme.getTextSecondary(context),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'What would you like to read?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            ),

            // Form fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    ContextaTextField(
                      label: 'Book Title',
                      placeholder: 'Enter the title...',
                      value: _title,
                      error: _titleError,
                      autofocus: true,
                      onChanged: _handleTitleChange,
                      onSubmitted: _canSave ? _handlePlaceOnShelf : null,
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 16),

                    // Author field with suggestions
                    ContextaTextField(
                      label: 'Author (optional)',
                      placeholder: "Enter the author's name",
                      value: _author,
                      onChanged: _handleAuthorChange,
                      onSubmitted: _canSave ? _handlePlaceOnShelf : null,
                      textInputAction: TextInputAction.done,
                    ),

                    // Author suggestions strip
                    SuggestionStrip(
                      suggestions: _authorSuggestions,
                      onSelect: _handleAuthorSuggestionSelect,
                      isVisible: _showAuthorSuggestions,
                    ),

                    const SizedBox(height: 20),

                    // Book preview card (appears as user types)
                    AnimatedBuilder(
                      animation: _previewController,
                      builder: (context, child) {
                        if (_previewOpacity.value == 0) {
                          return const SizedBox.shrink();
                        }

                        return Opacity(
                          opacity: _previewOpacity.value,
                          child: Transform.scale(
                            scale: _previewScale.value,
                            alignment: Alignment.topCenter,
                            child: child,
                          ),
                        );
                      },
                      child: _buildPreviewCard(context),
                    ),
                  ],
                ),
              ),
            ),

            // Place on Shelf button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: PrimaryButton(
                label: 'Place on Shelf',
                icon: Icons.check_rounded,
                fullWidth: true,
                disabled: !_canSave,
                loading: _isPlacing,
                onPressed: _handlePlaceOnShelf,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Container(
      key: _previewCardKey,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkPaper : AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border:
            isDark
                ? Border.all(color: AppTheme.darkBorderSubtle, width: 0.5)
                : null,
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: AppTheme.charcoal.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Row(
        children: [
          // Book info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title.trim().isEmpty ? 'Your Book' : _title.trim(),
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_author.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'by ${_author.trim()}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.getTextSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 12,
                      color: AppTheme.getTextMuted(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '0 words',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppTheme.getTextMuted(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Arrow hint
          Icon(
            Icons.north_rounded,
            size: 20,
            color: AppTheme.getTextMuted(context).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
