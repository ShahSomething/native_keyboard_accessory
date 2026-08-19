import 'package:flutter/foundation.dart';

/// Which text fields get the accessory bar.
///
/// The three groups are separate switches because they are different problems.
/// A bar is only genuinely needed where the keyboard offers no way out on its
/// own — see the individual flags.
@immutable
class KeyboardAccessoryScope {
  /// Creates a scope. The defaults match [standard].
  const KeyboardAccessoryScope({
    this.numericKeyboards = true,
    this.multilineFields = true,
    this.singleLineTextFields = false,
  });

  /// Fields whose keyboard iOS renders with **no return key at all**: number,
  /// decimal, phone, and ASCII-number pads. Without a bar there is no built-in
  /// way to dismiss these or move on, so this defaults to on.
  final bool numericKeyboards;

  /// Fields whose return key **inserts a newline** instead of dismissing —
  /// multi-line fields, detected natively as a return key type of
  /// `UIReturnKeyDefault`, which is how Flutter maps
  /// `TextInputAction.newline`. These have a return key but still no exit, so
  /// this also defaults to on.
  final bool multilineFields;

  /// Fields whose return key already dismisses or advances, because
  /// `textInputAction` maps it to Done, Next, Search, and so on. A bar here
  /// duplicates an affordance the user already has and costs vertical space,
  /// so this defaults to off.
  final bool singleLineTextFields;

  /// The recommended default: every field that has no way out of its own, and
  /// nothing more.
  static const KeyboardAccessoryScope standard = KeyboardAccessoryScope();

  /// Only keyboards with no return key. Excludes multi-line fields.
  static const KeyboardAccessoryScope numericOnly = KeyboardAccessoryScope(
    multilineFields: false,
  );

  /// Every text field, including those whose return key already works.
  static const KeyboardAccessoryScope all = KeyboardAccessoryScope(
    singleLineTextFields: true,
  );

  /// No field. A live kill switch — the native patch stays installed but never
  /// returns a bar, so no rebuild is needed to turn the feature off.
  static const KeyboardAccessoryScope none = KeyboardAccessoryScope(
    numericKeyboards: false,
    multilineFields: false,
  );

  /// Whether no field at all would show the bar.
  bool get isEmpty =>
      !numericKeyboards && !multilineFields && !singleLineTextFields;

  /// A copy of this scope with the given flags replaced.
  KeyboardAccessoryScope copyWith({
    bool? numericKeyboards,
    bool? multilineFields,
    bool? singleLineTextFields,
  }) =>
      KeyboardAccessoryScope(
        numericKeyboards: numericKeyboards ?? this.numericKeyboards,
        multilineFields: multilineFields ?? this.multilineFields,
        singleLineTextFields: singleLineTextFields ?? this.singleLineTextFields,
      );

  /// Serializes this scope for the method channel.
  Map<String, Object?> toMap() => <String, Object?>{
        'numericKeyboards': numericKeyboards,
        'multilineFields': multilineFields,
        'singleLineTextFields': singleLineTextFields,
      };

  @override
  bool operator ==(Object other) =>
      other is KeyboardAccessoryScope &&
      other.numericKeyboards == numericKeyboards &&
      other.multilineFields == multilineFields &&
      other.singleLineTextFields == singleLineTextFields;

  @override
  int get hashCode =>
      Object.hash(numericKeyboards, multilineFields, singleLineTextFields);

  @override
  String toString() => 'KeyboardAccessoryScope('
      'numericKeyboards: $numericKeyboards, '
      'multilineFields: $multilineFields, '
      'singleLineTextFields: $singleLineTextFields)';
}
