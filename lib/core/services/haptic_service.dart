import 'package:flutter/services.dart';

/// Lightweight haptic feedback helpers.
/// Each call is fire-and-forget and silently no-ops on web / unsupported
/// platforms.
///
/// Use the right intensity for the right context:
/// - [tap]      → button presses, small toggles
/// - [select]   → list item selection, picker changes
/// - [success]  → completed actions (message sent, photo uploaded)
/// - [warning]  → confirmation dialogs, undo prompts
/// - [error]    → failures
/// - [impact]   → strong physical feedback (level up, achievement)
class Haptic {
  Haptic._();

  static Future<void> tap() => HapticFeedback.lightImpact();
  static Future<void> select() => HapticFeedback.selectionClick();
  static Future<void> success() => HapticFeedback.mediumImpact();
  static Future<void> warning() => HapticFeedback.mediumImpact();
  static Future<void> error() => HapticFeedback.heavyImpact();
  static Future<void> impact() => HapticFeedback.heavyImpact();
}
