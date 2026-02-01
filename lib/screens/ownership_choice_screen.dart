import 'package:flutter/material.dart';
import '../main.dart' show isFirebaseAvailable;
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/contexta_snackbar.dart';
import '../widgets/logo.dart';
import '../widgets/loading_dots.dart';
import '../services/backup_service.dart';
import '../widgets/restore_prompt_sheet.dart';

/// First-launch screen for ownership choice.
///
/// Presents the user with two equal-weight options:
/// - Continue locally (stored only on this device)
/// - Continue with Google (backup & restore across devices)
///
/// No default option. No pressure. User always chooses.
class OwnershipChoiceScreen extends StatefulWidget {
  final VoidCallback onChoiceComplete;
  final Future<void> Function()? onLibraryChanged;

  const OwnershipChoiceScreen({
    super.key,
    required this.onChoiceComplete,
    this.onLibraryChanged,
  });

  @override
  State<OwnershipChoiceScreen> createState() => _OwnershipChoiceScreenState();
}

class _OwnershipChoiceScreenState extends State<OwnershipChoiceScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _loadingMessage;

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleLocalChoice() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Setting up your library…';
    });

    await _authService.chooseLocalMode();

    if (mounted) {
      widget.onChoiceComplete();
      if (widget.onLibraryChanged != null) {
        await widget.onLibraryChanged!();
      }
    }
  }

  Future<void> _handleGoogleChoice() async {
    if (!isFirebaseAvailable) {
      _showErrorSnackbar('Cloud backup is not available in this build');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Connecting…';
    });

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;

    switch (result) {
      case AuthResult.success:
        final backupService = BackupService();
        final hasCloud = await backupService.hasCloudData();
        if (!mounted) return;
        if (hasCloud) {
          final snapshot = await backupService.getCloudSnapshot();
          if (!mounted) return;
          if (snapshot != null) {
            final choice = await RestorePromptSheet.show(
              context,
              snapshot: snapshot,
            );
            if (!mounted) return;
            if (choice == RestoreChoice.restore) {
              setState(() {
                _isLoading = true;
                _loadingMessage = 'Restoring from cloud…';
              });
              await backupService.restoreFromCloud();
              if (!mounted) return;
              if (widget.onLibraryChanged != null) {
                await widget.onLibraryChanged!();
              }
              setState(() {
                _isLoading = false;
                _loadingMessage = null;
              });
            }
          }
        } else {
          if (widget.onLibraryChanged != null) {
            await widget.onLibraryChanged!();
          }
        }
        debugPrint(
          'OwnershipChoiceScreen: Sign-in success, calling onChoiceComplete',
        );
        widget.onChoiceComplete();
        break;
      case AuthResult.cancelled:
        debugPrint('OwnershipChoiceScreen: Sign-in cancelled');
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
        break;
      case AuthResult.error:
        debugPrint('OwnershipChoiceScreen: Sign-in error');
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
        _showErrorSnackbar();
        break;
    }
  }

  void _showErrorSnackbar([String? message]) {
    ContextaSnackbar.showError(
      context,
      message ?? 'Something went wrong. Please try again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child:
            _isLoading
                ? _buildLoadingState(theme)
                : _buildChoiceContent(theme, colorScheme, isDark),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Logo(variant: LogoVariant.icon, size: LogoSize.lg),
          const SizedBox(height: 32),
          const LoadingDots(),
          const SizedBox(height: 16),
          Text(
            _loadingMessage ?? 'Loading…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceContent(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              const Logo(variant: LogoVariant.icon, size: LogoSize.lg),
              const SizedBox(height: 48),

              // Title
              Text(
                'Your reading, your way',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Body
              Text(
                'Your books and words belong to you.\nChoose how you\'d like to keep them.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Choice buttons
              _OwnershipButton(
                title: 'Continue locally',
                subtitle: 'Stored only on this device',
                icon: Icons.phone_android_rounded,
                onTap: _handleLocalChoice,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              _OwnershipButton(
                title: 'Continue with Google',
                subtitle: 'Back up and restore anytime',
                icon: Icons.cloud_outlined,
                onTap: _handleGoogleChoice,
                isDark: isDark,
                colorScheme: colorScheme,
                isGoogle: true,
              ),

              const SizedBox(height: 32),

              // Footnote
              Text(
                'You can change this later in Settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A calm, equal-weight button for ownership choice.
class _OwnershipButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme colorScheme;
  final bool isGoogle;

  const _OwnershipButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.colorScheme,
    this.isGoogle = false,
  });

  @override
  State<_OwnershipButton> createState() => _OwnershipButtonState();
}

class _OwnershipButtonState extends State<_OwnershipButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.isDark ? AppTheme.darkPaperElevated : AppTheme.paper;
    final borderColor = widget.isDark ? AppTheme.darkBorder : AppTheme.border;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTheme.buttonPressDuration,
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: borderColor),
          boxShadow:
              _isPressed
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: widget.isDark ? 0.2 : 0.05,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16,
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: widget.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
