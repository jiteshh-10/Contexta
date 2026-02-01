import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ownership_state.dart';

/// Handles Google Sign-In authentication for cloud backup.
///
/// Provides a calm, non-intrusive authentication experience
/// that respects user choice and never forces sign-in.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Preferences keys
  static const String _keyOwnershipMode = 'ownership_mode';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyLastBackup = 'last_backup_time';

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // State stream
  final _stateController = StreamController<OwnershipState>.broadcast();
  Stream<OwnershipState> get stateStream => _stateController.stream;

  // Current state
  OwnershipState _currentState = const OwnershipState();
  OwnershipState get currentState => _currentState;

  /// Initialize the service and restore saved state
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved ownership mode
    final modeString = prefs.getString(_keyOwnershipMode);
    final mode = _parseOwnershipMode(modeString);

    // Load user info if signed in
    final userId = prefs.getString(_keyUserId);
    final userEmail = prefs.getString(_keyUserEmail);
    final lastBackupMillis = prefs.getInt(_keyLastBackup);

    DateTime? lastBackup;
    if (lastBackupMillis != null) {
      lastBackup = DateTime.fromMillisecondsSinceEpoch(lastBackupMillis);
    }

    // Try silent sign-in if previously signed in
    if (mode == OwnershipMode.cloud && userId != null) {
      try {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          // Also sign in to Firebase Auth silently
          final googleAuth = await account.authentication;
          final credential = firebase_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final userCredential = await firebase_auth.FirebaseAuth.instance
              .signInWithCredential(credential);
          final firebaseUser = userCredential.user;

          _currentState = OwnershipState.cloud(
            userId: firebaseUser?.uid ?? userId,
            userEmail: account.email,
            lastBackupTime: lastBackup,
          );
        } else {
          // Token expired, but keep cloud mode - will prompt on next backup
          _currentState = OwnershipState(
            mode: OwnershipMode.cloud,
            userId: userId,
            userEmail: userEmail,
            lastBackupTime: lastBackup,
          );
        }
      } catch (e) {
        debugPrint('AuthService: Silent sign-in failed: $e');
        // Silent sign-in failed, but keep saved state
        _currentState = OwnershipState(
          mode: mode,
          userId: userId,
          userEmail: userEmail,
          lastBackupTime: lastBackup,
        );
      }
    } else if (mode == OwnershipMode.local) {
      _currentState = OwnershipState.local();
    }
    // If undecided, state remains default

    _stateController.add(_currentState);
  }

  /// Check if this is the first launch (no ownership choice made)
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_keyOwnershipMode);
  }

  /// User chose local-only mode
  Future<void> chooseLocalMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOwnershipMode, 'local');

    _currentState = OwnershipState.local();
    _stateController.add(_currentState);
  }

  /// Sign in with Google and enable cloud backup
  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('AuthService: Starting Google Sign-In...');
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        debugPrint('AuthService: User cancelled sign-in');
        return AuthResult.cancelled;
      }

      debugPrint('AuthService: Google Sign-In successful - ${account.email}');

      // Get Google Auth credentials
      final googleAuth = await account.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase Auth
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        debugPrint('AuthService: Firebase Auth failed - no user returned');
        return AuthResult.error;
      }

      debugPrint(
        'AuthService: Firebase Auth successful - UID: ${firebaseUser.uid}',
      );

      // Save to preferences - use Firebase UID, NOT Google ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyOwnershipMode, 'cloud');
      await prefs.setString(_keyUserId, firebaseUser.uid);
      await prefs.setString(_keyUserEmail, account.email);

      _currentState = OwnershipState.cloud(
        userId: firebaseUser.uid,
        userEmail: account.email,
      );
      _stateController.add(_currentState);

      return AuthResult.success;
    } catch (e, stackTrace) {
      debugPrint('AuthService: Sign-in error - $e');
      debugPrint('AuthService: Stack trace - $stackTrace');
      return AuthResult.error;
    }
  }

  /// Sign out and switch to local mode
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (_) {
      // Ignore sign-out errors
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOwnershipMode, 'local');
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    // Keep last backup time for reference

    _currentState = OwnershipState.local();
    _stateController.add(_currentState);
  }

  /// Update last backup time
  Future<void> updateLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastBackup, time.millisecondsSinceEpoch);

    _currentState = _currentState.copyWith(
      lastBackupTime: time,
      isBackupInProgress: false,
      backupError: null,
    );
    _stateController.add(_currentState);
  }

  /// Set backup in progress state
  void setBackupInProgress(bool inProgress) {
    _currentState = _currentState.copyWith(
      isBackupInProgress: inProgress,
      backupError: null,
    );
    _stateController.add(_currentState);
  }

  /// Set backup error
  void setBackupError(String? error) {
    _currentState = _currentState.copyWith(
      isBackupInProgress: false,
      backupError: error,
    );
    _stateController.add(_currentState);
  }

  /// Get current Google user ID (for Firestore path)
  String? get currentUserId => _currentState.userId;

  /// Check if currently signed in to Google
  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// Parse ownership mode from string
  OwnershipMode _parseOwnershipMode(String? value) {
    switch (value) {
      case 'local':
        return OwnershipMode.local;
      case 'cloud':
        return OwnershipMode.cloud;
      default:
        return OwnershipMode.undecided;
    }
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}

/// Result of authentication attempt
enum AuthResult {
  /// Sign-in successful
  success,

  /// User cancelled sign-in
  cancelled,

  /// An error occurred
  error,
}
