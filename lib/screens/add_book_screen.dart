import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/contexta_app_bar.dart';
import '../widgets/contexta_text_field.dart';
import '../widgets/primary_button.dart';

/// Add book screen with validation and sticky bottom action
/// Features: Title (required), Author (optional), real-time validation
class AddBookScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(String title, String author) onSave;

  const AddBookScreen({super.key, required this.onBack, required this.onSave});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  String _title = '';
  String _author = '';
  String? _titleError;
  bool _isSaving = false;

  bool get _canSave => _title.trim().isNotEmpty && !_isSaving;

  void _handleSave() async {
    // Validate
    if (_title.trim().isEmpty) {
      setState(() => _titleError = 'Please enter a book title');
      HapticFeedback.lightImpact();
      return;
    }

    // Simulate brief save animation
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 200));

    // Haptic feedback on success
    HapticFeedback.mediumImpact();

    // Save and navigate back
    widget.onSave(_title.trim(), _author.trim());
  }

  void _handleTitleChange(String value) {
    setState(() {
      _title = value;
      // Clear error when user starts typing
      if (_titleError != null && value.trim().isNotEmpty) {
        _titleError = null;
      }
    });
  }

  void _handleAuthorChange(String value) {
    setState(() => _author = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ContextaAppBar(
        title: 'Add a Book to Your Shelf',
        onBack: widget.onBack,
      ),
      body: Column(
        children: [
          // Scrollable form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle
                  Text(
                    'What would you like to read?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontStyle: FontStyle.italic,
                      fontSize: 15,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title field (required)
                  ContextaTextField(
                    label: 'Book Title',
                    placeholder: 'Enter the title...',
                    value: _title,
                    error: _titleError,
                    autofocus: true,
                    onChanged: _handleTitleChange,
                    onSubmitted: _canSave ? _handleSave : null,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 24),

                  // Author field (optional)
                  ContextaTextField(
                    label: 'Author (optional)',
                    placeholder: "Enter the author's name",
                    value: _author,
                    onChanged: _handleAuthorChange,
                    onSubmitted: _canSave ? _handleSave : null,
                    textInputAction: TextInputAction.done,
                  ),

                  const SizedBox(height: 24),

                  // Helper text
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppTheme.getTextMuted(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can always edit these details later.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppTheme.getTextMuted(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sticky bottom action bar
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: AppTheme.getBorder(context), width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: 'Place on Shelf',
                icon: Icons.check_rounded,
                fullWidth: true,
                disabled: !_canSave,
                loading: _isSaving,
                onPressed: _handleSave,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
