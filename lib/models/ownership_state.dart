/// Represents the user's ownership choice for data storage.
///
/// This determines how the app handles data persistence and backup.
enum OwnershipMode {
  /// User has not made a choice yet (first launch)
  undecided,

  /// User chose local-only storage
  local,

  /// User signed in with Google for cloud backup
  cloud,
}

/// Current state of the user's ownership and backup configuration.
class OwnershipState {
  final OwnershipMode mode;
  final String? userId;
  final String? userEmail;
  final DateTime? lastBackupTime;
  final bool isBackupInProgress;
  final String? backupError;

  const OwnershipState({
    this.mode = OwnershipMode.undecided,
    this.userId,
    this.userEmail,
    this.lastBackupTime,
    this.isBackupInProgress = false,
    this.backupError,
  });

  /// Check if user is signed in
  bool get isSignedIn => userId != null && mode == OwnershipMode.cloud;

  /// Check if user has made an ownership choice
  bool get hasChosenOwnership => mode != OwnershipMode.undecided;

  /// Check if cloud backup is enabled
  bool get isCloudEnabled => mode == OwnershipMode.cloud && isSignedIn;

  /// Create a copy with updated fields
  OwnershipState copyWith({
    OwnershipMode? mode,
    String? userId,
    String? userEmail,
    DateTime? lastBackupTime,
    bool? isBackupInProgress,
    String? backupError,
  }) {
    return OwnershipState(
      mode: mode ?? this.mode,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      isBackupInProgress: isBackupInProgress ?? this.isBackupInProgress,
      backupError: backupError ?? this.backupError,
    );
  }

  /// Create state for local-only mode
  factory OwnershipState.local() {
    return const OwnershipState(mode: OwnershipMode.local);
  }

  /// Create state for cloud mode with user info
  factory OwnershipState.cloud({
    required String userId,
    String? userEmail,
    DateTime? lastBackupTime,
  }) {
    return OwnershipState(
      mode: OwnershipMode.cloud,
      userId: userId,
      userEmail: userEmail,
      lastBackupTime: lastBackupTime,
    );
  }

  /// Get a human-readable status description
  String get statusDescription {
    switch (mode) {
      case OwnershipMode.undecided:
        return 'Choose how to store your library';
      case OwnershipMode.local:
        return 'Your library is stored on this device';
      case OwnershipMode.cloud:
        if (isBackupInProgress) {
          return 'Saving your library…';
        }
        if (lastBackupTime != null) {
          return 'Your library is backed up and ready to restore';
        }
        return 'Your library is backed up to the cloud';
    }
  }

  /// Get last backup time as human-readable string
  String? get lastBackupDescription {
    if (lastBackupTime == null) return null;

    final now = DateTime.now();
    final diff = now.difference(lastBackupTime!);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${lastBackupTime!.day}/${lastBackupTime!.month}/${lastBackupTime!.year}';
  }
}
