/// A button on the native keyboard accessory bar.
enum KeyboardAccessoryAction {
  /// The up chevron — move focus to the previous field.
  previous,

  /// The down chevron — move focus to the next field.
  next,

  /// The checkmark — dismiss the keyboard.
  done;

  /// Parses the wire value sent by the platform side, or null if it is not
  /// a known action — a forward-compatibility guard so a newer platform
  /// implementation cannot crash an older Dart side.
  static KeyboardAccessoryAction? tryParse(Object? value) => switch (value) {
        'previous' => KeyboardAccessoryAction.previous,
        'next' => KeyboardAccessoryAction.next,
        'done' => KeyboardAccessoryAction.done,
        _ => null,
      };
}

/// Called when the user taps a bar button.
///
/// Return `true` to consume the action. Returning `false` (or not supplying a
/// handler) falls through to the default behaviour, which is focus traversal:
/// `previousFocus()`, `nextFocus()`, and `unfocus()` on the primary focus node.
typedef KeyboardAccessoryActionHandler = bool Function(
  KeyboardAccessoryAction action,
);
