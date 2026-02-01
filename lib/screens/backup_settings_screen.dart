import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart' show isFirebaseAvailable;
import '../models/ownership_state.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/local_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/contexta_dialog.dart';
import '../widgets/contexta_snackbar.dart';
import '../widgets/loading_dots.dart';
import '../widgets/restore_prompt_sheet.dart';

/// Settings screen for backup and library management.
///
/// Shows:
/// - Current backup status (local only / signed in)
/// - Last backup time (if signed in)
/// - Export/Import options
/// - Sign in/out options
class BackupSettingsScreen extends StatefulWidget {
  final Future<void> Function()? onLibraryChanged;

  const BackupSettingsScreen({super.key, this.onLibraryChanged});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  final AuthService _authService = AuthService();
  final BackupService _backupService = BackupService();
  final LocalExportService _exportService = LocalExportService();

  OwnershipState _state = const OwnershipState();
  bool _isExporting = false;
  bool _isSigningIn = false;
  StreamSubscription<OwnershipState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _state = _authService.currentState;
    _stateSubscription = _authService.stateStream.listen((state) {
      if (mounted) {
        setState(() => _state = state);
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() => _isSigningIn = true);

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isSigningIn = false);

    if (result == AuthResult.success) {
      // Check if cloud data exists
      final hasCloud = await _backupService.hasCloudData();
      final isLocalEmpty = await _backupService.isLocalDatabaseEmpty();

      if (!mounted) return;

      if (hasCloud && !isLocalEmpty) {
        // Conflict: both local and cloud have data
        final snapshot = await _backupService.getCloudSnapshot();
        if (snapshot != null && mounted) {
          final choice = await DataConflictSheet.show(
            context,
            cloudSnapshot: snapshot,
          );

          if (choice == ConflictChoice.restoreCloud) {
            await _performRestore();
          }
        }
      } else if (hasCloud && isLocalEmpty) {
        // No local data, offer to restore
        final snapshot = await _backupService.getCloudSnapshot();
        if (snapshot != null && mounted) {
          final choice = await RestorePromptSheet.show(
            context,
            snapshot: snapshot,
          );

          if (choice == RestoreChoice.restore) {
            await _performRestore();
          }
        }
      }
      // If no cloud data, just enable backup going forward

      ContextaSnackbar.showSuccess(context, 'Signed in successfully');
      if (widget.onLibraryChanged != null) {
        await widget.onLibraryChanged!();
      }
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else if (result == AuthResult.error) {
      ContextaSnackbar.showError(
        context,
        'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _performRestore() async {
    // Show restoring sheet
    RestoringSheet.show(context);

    final result = await _backupService.restoreFromCloud();

    if (!mounted) return;
    Navigator.pop(context); // Close restoring sheet

    switch (result) {
      case RestoreResult.success:
        ContextaSnackbar.showSuccess(context, 'Library restored');
        if (widget.onLibraryChanged != null) {
          await widget.onLibraryChanged!();
        }
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        break;
      case RestoreResult.noData:
        ContextaSnackbar.show(context, 'No backup found');
        break;
      case RestoreResult.incompatible:
        ContextaSnackbar.showWarning(context, 'Backup version not compatible');
        break;
      case RestoreResult.error:
        ContextaSnackbar.showError(
          context,
          'Restore failed. Please try again.',
        );
        break;
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Sign out of backup?',
      message:
          'Your library will stay on this device.\nCloud backup will stop.',
      confirmLabel: 'Sign out',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        ContextaSnackbar.show(context, 'Signed out');
      }
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    final result = await _exportService.exportLibrary();

    if (!mounted) return;

    setState(() => _isExporting = false);

    if (result.isSuccess && result.filePath != null) {
      // Share the file
      await _exportService.shareExport(result.filePath!);
    } else if (result.isEmpty) {
      ContextaSnackbar.show(context, 'Your library is empty');
    } else {
      ContextaSnackbar.showError(context, 'Export failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Library backup',
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _buildStatusCard(theme, colorScheme, isDark),
            const SizedBox(height: 32),

            // Actions section
            Text(
              'Actions',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Export button
            _SettingsButton(
              icon: Icons.file_download_outlined,
              title: 'Export library',
              subtitle: 'Create a private backup file',
              onTap: _isExporting ? null : _handleExport,
              isLoading: _isExporting,
              isDark: isDark,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),

            // Sign in/out button
            if (_state.isSignedIn)
              _SettingsButton(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'Stop cloud backup',
                onTap: _handleSignOut,
                isDark: isDark,
                colorScheme: colorScheme,
                isDestructive: true,
              )
            else if (isFirebaseAvailable)
              _SettingsButton(
                icon: Icons.cloud_outlined,
                title: 'Sign in with Google',
                subtitle: 'Back up and restore anytime',
                onTap: _isSigningIn ? null : _handleSignIn,
                isLoading: _isSigningIn,
                isDark: isDark,
                colorScheme: colorScheme,
              )
            else
              _buildFirebaseNotConfiguredCard(theme, colorScheme, isDark),

            const SizedBox(height: 32),

            // Privacy note
            Center(
              child: Text(
                'Your library is private and never shared.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseNotConfiguredCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final backgroundColor =
        isDark ? AppTheme.darkPaperElevated : AppTheme.beigeDarker;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cloud backup not available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Firebase not configured for this build',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final backgroundColor =
        isDark ? AppTheme.darkPaperElevated : AppTheme.paper;

    final iconBgColor =
        _state.isSignedIn
            ? colorScheme.primary.withValues(alpha: 0.1)
            : (isDark ? AppTheme.darkPaperHighest : AppTheme.beigeDarker);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _state.isSignedIn
                  ? Icons.cloud_done_outlined
                  : Icons.phone_android_rounded,
              color:
                  _state.isSignedIn
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _state.statusDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                if (_state.lastBackupDescription != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last backup: ${_state.lastBackupDescription}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                if (_state.backupError != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _state.backupError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A calm settings button with icon and subtitle.
class _SettingsButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDark;
  final ColorScheme colorScheme;
  final bool isLoading;
  final bool isDestructive;

  const _SettingsButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    required this.colorScheme,
    this.isLoading = false,
    this.isDestructive = false,
  });

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.isDark ? AppTheme.darkPaperElevated : AppTheme.paper;
    final borderColor = widget.isDark ? AppTheme.darkBorder : AppTheme.border;

    final iconColor =
        widget.isDestructive
            ? (widget.isDark ? AppTheme.darkError : AppTheme.error)
            : widget.colorScheme.primary;

    return GestureDetector(
      onTapDown:
          widget.onTap == null
              ? null
              : (_) => setState(() => _isPressed = true),
      onTapUp:
          widget.onTap == null
              ? null
              : (_) => setState(() => _isPressed = false),
      onTapCancel:
          widget.onTap == null
              ? null
              : () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTheme.buttonPressDuration,
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            if (widget.isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: LoadingDots(compact: true),
              )
            else
              Icon(widget.icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color:
                          widget.isDestructive
                              ? iconColor
                              : widget.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.colorScheme.onSurface.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.isLoading)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: widget.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}
