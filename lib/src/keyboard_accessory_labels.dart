import 'package:flutter/foundation.dart';

/// VoiceOver labels for the bar's buttons.
///
/// The buttons are icon-only, so without these a screen reader announces
/// nothing useful. They are supplied from Dart rather than an iOS strings file
/// because a Flutter app's translations live on the Dart side — pass values
/// from whatever localization the host app already uses, and push a new
/// [KeyboardAccessoryLabels] when the locale changes.
@immutable
class KeyboardAccessoryLabels {
  /// Creates a set of labels, defaulting to English.
  const KeyboardAccessoryLabels({
    this.previous = 'Previous',
    this.next = 'Next',
    this.done = 'Done',
  });

  /// Announced for the up chevron.
  final String previous;

  /// Announced for the down chevron.
  final String next;

  /// Announced for the checkmark.
  final String done;

  /// Serializes these labels for the method channel.
  Map<String, Object?> toMap() => <String, Object?>{
        'previousLabel': previous,
        'nextLabel': next,
        'doneLabel': done,
      };

  @override
  bool operator ==(Object other) =>
      other is KeyboardAccessoryLabels &&
      other.previous == previous &&
      other.next == next &&
      other.done == done;

  @override
  int get hashCode => Object.hash(previous, next, done);
}
