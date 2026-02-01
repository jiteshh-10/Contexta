import 'package:flutter/material.dart';
import '../models/backup_snapshot.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_dots.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';

/// Bottom sheet shown when cloud data is found after sign-in.
///
/// Gives the user a calm choice:
/// - Restore my library (replace local with cloud)
/// - Start fresh (ignore cloud data)
///
/// No auto-merge. No pressure. Clear consequences.
class RestorePromptSheet extends StatefulWidget {
  final BackupSnapshot snapshot;
  final VoidCallback onRestore;
  final VoidCallback onStartFresh;

  const RestorePromptSheet({
    super.key,
    required this.snapshot,
    required this.onRestore,
    required this.onStartFresh,
  });

  /// Show the restore prompt as a modal bottom sheet
  static Future<RestoreChoice?> show(
    BuildContext context, {
    required BackupSnapshot snapshot,
  }) {
    return showModalBottomSheet<RestoreChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => RestorePromptSheet(
            snapshot: snapshot,
            onRestore: () => Navigator.pop(context, RestoreChoice.restore),
            onStartFresh:
                () => Navigator.pop(context, RestoreChoice.startFresh),
          ),
    );
  }

  @override
  State<RestorePromptSheet> createState() => _RestorePromptSheetState();
}

class _RestorePromptSheetState extends State<RestorePromptSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppTheme.darkPaperElevated : AppTheme.paper;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusSheet),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),

                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_done_outlined,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Welcome back',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Body
                Text(
                  'We found your library from a previous device.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Summary
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    widget.snapshot.summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Would you like to bring it back?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Actions
                PrimaryButton(
                  label: 'Restore my library',
                  onPressed: widget.onRestore,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Start fresh',
                  onPressed: widget.onStartFresh,
                ),
                const SizedBox(height: 16),

                // Subtle note
                Text(
                  'You can always restore later from Settings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// User's choice from the restore prompt
enum RestoreChoice { restore, startFresh }

/// Sheet shown while restoring is in progress
class RestoringSheet extends StatelessWidget {
  const RestoringSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const RestoringSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppTheme.darkPaperElevated : AppTheme.paper;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingDots(),
              const SizedBox(height: 24),
              Text(
                'Restoring your library',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bringing your books and words back.\nThis won\'t take long.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conflict resolution sheet when signing in with existing local data
class DataConflictSheet extends StatefulWidget {
  final BackupSnapshot cloudSnapshot;
  final VoidCallback onKeepLocal;
  final VoidCallback onRestoreCloud;

  const DataConflictSheet({
    super.key,
    required this.cloudSnapshot,
    required this.onKeepLocal,
    required this.onRestoreCloud,
  });

  static Future<ConflictChoice?> show(
    BuildContext context, {
    required BackupSnapshot cloudSnapshot,
  }) {
    return showModalBottomSheet<ConflictChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DataConflictSheet(
            cloudSnapshot: cloudSnapshot,
            onKeepLocal: () => Navigator.pop(context, ConflictChoice.keepLocal),
            onRestoreCloud:
                () => Navigator.pop(context, ConflictChoice.restoreCloud),
          ),
    );
  }

  @override
  State<DataConflictSheet> createState() => _DataConflictSheetState();
}

class _DataConflictSheetState extends State<DataConflictSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppTheme.darkPaperElevated : AppTheme.paper;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Choose how to continue',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Body
              Text(
                'You already have books and words on this device.\n\nWhat would you like to do?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Cloud option
              _ConflictOption(
                icon: Icons.cloud_download_outlined,
                title: 'Restore my previous library',
                subtitle: widget.cloudSnapshot.summary,
                onTap: widget.onRestoreCloud,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Local option
              _ConflictOption(
                icon: Icons.phone_android_rounded,
                title: 'Keep what\'s on this device',
                subtitle: 'Continue with current library',
                onTap: widget.onKeepLocal,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConflictOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;

  const _ConflictOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  State<_ConflictOption> createState() => _ConflictOptionState();
}

class _ConflictOptionState extends State<_ConflictOption> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.isDark ? AppTheme.darkPaperHighest : AppTheme.beige;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTheme.buttonPressDuration,
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: widget.isDark ? AppTheme.darkBorder : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: widget.colorScheme.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: widget.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// User's choice from the conflict resolution
enum ConflictChoice { keepLocal, restoreCloud }
