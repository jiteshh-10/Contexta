import 'package:flutter/material.dart';

/// Enum representing why a word was difficult for the reader
/// Optional field that makes Contexta feel more thoughtful
enum DifficultyReason {
  meaningUnclear(
    label: 'Meaning unclear',
    description: 'The definition wasn\'t obvious',
    icon: Icons.help_outline_rounded,
    color: Color(0xFF5B8DEF),
  ),
  contextConfusing(
    label: 'Context confusing',
    description: 'Hard to understand in this context',
    icon: Icons.menu_book_rounded,
    color: Color(0xFFE89B3E),
  ),
  philosophicalUsage(
    label: 'Philosophical',
    description: 'Used in a deeper, abstract sense',
    icon: Icons.psychology_outlined,
    color: Color(0xFF9B6EE8),
  ),
  archaicUsage(
    label: 'Old/Archaic',
    description: 'Outdated or rarely used term',
    icon: Icons.history_edu_rounded,
    color: Color(0xFF6EAE8B),
  );

  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const DifficultyReason({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  /// Convert to string for storage
  String toStorageString() => name;

  /// Create from storage string
  static DifficultyReason? fromStorageString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DifficultyReason.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}
