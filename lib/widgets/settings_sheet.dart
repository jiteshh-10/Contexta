import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/book.dart';
import '../screens/backup_settings_screen.dart';

/// Settings bottom sheet for app preferences
///
/// Currently includes:
/// - Theme mode toggle
/// - Reading consistency indicator toggle
/// - Library backup
/// - Export all words option
class SettingsSheet extends StatefulWidget {
  final bool showReadingStreak;
  final VoidCallback onToggleReadingStreak;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onClose;
  final List<Book>? books;
  final VoidCallback? onExportAll;
  final Future<void> Function()? onLibraryChanged;

  const SettingsSheet({
    super.key,
    required this.showReadingStreak,
    required this.onToggleReadingStreak,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onClose,
    this.books,
    this.onExportAll,
    this.onLibraryChanged,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late bool _showReadingStreak;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _showReadingStreak = widget.showReadingStreak;
    _isDarkMode = widget.isDarkMode;
  }

  void _handleStreakToggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _showReadingStreak = !_showReadingStreak;
    });
    widget.onToggleReadingStreak();
  }

  void _handleThemeToggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    widget.onToggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    // Check if any book has words for export option
    final hasAnyWords = widget.books?.any((b) => b.hasWords) ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(
                  Icons.close,
                  color: AppTheme.getTextSecondary(context),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Theme mode toggle
          _SettingsToggle(
            title: _isDarkMode ? 'Dark mode' : 'Light mode',
            description: 'Switch between light and dark appearance',
            value: _isDarkMode,
            onChanged: (_) => _handleThemeToggle(),
          ),

          const SizedBox(height: 12),

          // Reading consistency toggle
          _SettingsToggle(
            title: 'Show reading consistency',
            description: 'Display a subtle indicator of your reading activity',
            value: _showReadingStreak,
            onChanged: (_) => _handleStreakToggle(),
          ),

          // Export all words option
          if (hasAnyWords && widget.onExportAll != null) ...[
            const SizedBox(height: 12),
            _SettingsAction(
              title: 'Export all words',
              description: 'Share your vocabulary as PDF, Markdown, or text',
              icon: Icons.ios_share_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onClose();
                // Small delay to let sheet close smoothly
                Future.delayed(const Duration(milliseconds: 200), () {
                  widget.onExportAll!();
                });
              },
            ),
          ],

          const SizedBox(height: 12),

          // Library backup navigation
          _SettingsNavigation(
            title: 'Library backup',
            description: 'Back up, restore, or export your library',
            icon: Icons.cloud_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              final navigator = Navigator.of(context);
              widget.onClose();
              Future.delayed(const Duration(milliseconds: 200), () {
                navigator.push(
                  MaterialPageRoute(
                    builder:
                        (context) => BackupSettingsScreen(
                          onLibraryChanged: widget.onLibraryChanged,
                        ),
                  ),
                );
              });
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Reusable settings toggle widget
class _SettingsToggle extends StatefulWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SettingsToggle> createState() => _SettingsToggleState();
}

class _SettingsToggleState extends State<_SettingsToggle> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _isPressed
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IgnorePointer(
              child: Switch.adaptive(
                value: widget.value,
                onChanged: (_) {},
                activeTrackColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings action button (non-toggle)
class _SettingsAction extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SettingsAction> createState() => _SettingsActionState();
}

class _SettingsActionState extends State<_SettingsAction> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _isPressed
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              widget.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings navigation item (navigates to another screen)
/// Icon is on the RIGHT side with a chevron for consistency
class _SettingsNavigation extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsNavigation({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SettingsNavigation> createState() => _SettingsNavigationState();
}

class _SettingsNavigationState extends State<_SettingsNavigation> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _isPressed
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              widget.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
