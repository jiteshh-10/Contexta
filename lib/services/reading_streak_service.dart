import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'database/database_service.dart';

/// Service for tracking reading consistency
///
/// Tracks unique days when words were saved, providing a subtle
/// indicator of reading continuity without daily pressure.
///
/// Key design principles:
/// - A "reading day" = at least one word saved on that calendar day
/// - Multiple words on same day count as one
/// - No daily streak pressure - just total active days
/// - Respects irregular reading patterns
class ReadingStreakService {
  // Singleton pattern
  static final ReadingStreakService _instance =
      ReadingStreakService._internal();
  factory ReadingStreakService() => _instance;
  ReadingStreakService._internal();

  final DatabaseService _db = DatabaseService();

  // Stream controller for notifying listeners of updates
  final _streakController = StreamController<ReadingStreakData>.broadcast();

  /// Stream of streak data updates
  Stream<ReadingStreakData> get streakStream => _streakController.stream;

  // Cache for current streak data
  ReadingStreakData? _cachedData;

  // Copy variants for display text
  static const List<String> _copyVariants = [
    'Words noted on {count} different days',
    'You\'ve returned to reading on {count} days',
    'Your notes span {count} reading days',
  ];

  // Random for copy variant selection
  final _random = Random();
  int _currentVariantIndex = 0;

  /// Initialize the service
  Future<void> initialize() async {
    // Rotate copy variant occasionally
    _currentVariantIndex = _random.nextInt(_copyVariants.length);

    // Load initial data
    await _refreshData();

    debugPrint('ReadingStreakService: Initialized');
  }

  /// Record a reading day (call when a word is saved)
  Future<void> recordReadingDay() async {
    final today = _formatDate(DateTime.now());

    try {
      // Check if today already recorded
      final existing = await _db.query(
        'reading_days',
        where: 'date = ?',
        whereArgs: [today],
      );

      if (existing.isEmpty) {
        // New day - insert and notify
        await _db.insert('reading_days', {
          'date': today,
          'created_at': DateTime.now().toIso8601String(),
        });

        debugPrint('ReadingStreakService: Recorded new reading day: $today');

        // Trigger haptic feedback for new day
        _triggerHaptic();

        // Refresh and notify listeners
        await _refreshData();
      }
    } catch (e) {
      debugPrint('ReadingStreakService: Error recording day: $e');
    }
  }

  /// Get current streak data
  Future<ReadingStreakData> getStreakData() async {
    if (_cachedData != null) return _cachedData!;
    await _refreshData();
    return _cachedData!;
  }

  /// Refresh streak data from database
  Future<void> _refreshData() async {
    try {
      final days = await _db.query('reading_days', orderBy: 'date DESC');

      final dates = days.map((d) => d['date'] as String).toList();

      final totalDays = dates.length;
      final currentStreak = _calculateCurrentStreak(dates);
      final recentDays = _getRecentDays(dates, 7);

      final oldData = _cachedData;

      _cachedData = ReadingStreakData(
        totalActiveDays: totalDays,
        currentStreak: currentStreak,
        recentDays: recentDays,
        displayText: _getDisplayText(totalDays),
        isNewDayAdded: oldData != null && totalDays > oldData.totalActiveDays,
      );

      _streakController.add(_cachedData!);
    } catch (e) {
      debugPrint('ReadingStreakService: Error refreshing data: $e');

      // Return empty data on error
      _cachedData = ReadingStreakData(
        totalActiveDays: 0,
        currentStreak: 0,
        recentDays: [],
        displayText: _getDisplayText(0),
        isNewDayAdded: false,
      );

      _streakController.add(_cachedData!);
    }
  }

  /// Calculate current consecutive streak
  int _calculateCurrentStreak(List<String> sortedDates) {
    if (sortedDates.isEmpty) return 0;

    final today = _formatDate(DateTime.now());
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // Check if streak is active (today or yesterday)
    if (sortedDates.first != today && sortedDates.first != yesterday) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < sortedDates.length - 1; i++) {
      final current = DateTime.parse(sortedDates[i]);
      final previous = DateTime.parse(sortedDates[i + 1]);
      final diff = current.difference(previous).inDays;

      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get recent days for dot visualization (last 7 days)
  List<ReadingDay> _getRecentDays(List<String> dates, int count) {
    final result = <ReadingDay>[];
    final dateSet = dates.toSet();
    final today = DateTime.now();

    for (int i = count - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = _formatDate(date);
      result.add(ReadingDay(date: date, isActive: dateSet.contains(dateStr)));
    }

    return result;
  }

  /// Get display text with current variant
  String _getDisplayText(int count) {
    if (count == 0) {
      return 'Start your reading journey today';
    }

    final template = _copyVariants[_currentVariantIndex];
    return template.replaceAll('{count}', count.toString());
  }

  /// Format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Trigger light haptic feedback
  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  /// Dispose resources
  void dispose() {
    _streakController.close();
  }
}

/// Data class representing reading streak information
class ReadingStreakData {
  /// Total number of unique active reading days
  final int totalActiveDays;

  /// Current consecutive streak (optional, for future use)
  final int currentStreak;

  /// Recent days for dot visualization (last 7 days)
  final List<ReadingDay> recentDays;

  /// Pre-formatted display text
  final String displayText;

  /// Whether a new day was just added (for animation)
  final bool isNewDayAdded;

  const ReadingStreakData({
    required this.totalActiveDays,
    required this.currentStreak,
    required this.recentDays,
    required this.displayText,
    required this.isNewDayAdded,
  });

  bool get hasAnyDays => totalActiveDays > 0;
}

/// Represents a single reading day
class ReadingDay {
  final DateTime date;
  final bool isActive;

  const ReadingDay({required this.date, required this.isActive});
}
