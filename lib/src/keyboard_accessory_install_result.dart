import 'package:flutter/foundation.dart';

/// What the native install actually managed to attach.
///
/// Reported rather than assumed because the bar is hosted by an engine-internal
/// class. If a future Flutter release renames or restructures that class, this
/// is how a host app finds out — at runtime, in a value it can log or assert on,
/// instead of through a silently missing bar.
@immutable
class KeyboardAccessoryInstallResult {
  /// Creates a result. Normally built by [fromMap] rather than directly.
  const KeyboardAccessoryInstallResult({
    required this.installed,
    required this.inputAccessoryPatched,
    required this.keyboardTypeHookInstalled,
  });

  /// The platform is not iOS, or the plugin is not registered.
  static const KeyboardAccessoryInstallResult unsupported =
      KeyboardAccessoryInstallResult(
    installed: false,
    inputAccessoryPatched: false,
    keyboardTypeHookInstalled: false,
  );

  /// Reads a result from the platform response, treating any missing or
  /// non-boolean entry as false.
  factory KeyboardAccessoryInstallResult.fromMap(Map<Object?, Object?>? map) {
    bool read(String key) => map?[key] == true;
    return KeyboardAccessoryInstallResult(
      installed: read('installed'),
      inputAccessoryPatched: read('inputAccessoryPatched'),
      keyboardTypeHookInstalled: read('keyboardTypeHookInstalled'),
    );
  }

  /// The engine's text input class was found.
  final bool installed;

  /// The accessory view is attached. This is the one that matters: false means
  /// no bar will ever appear.
  final bool inputAccessoryPatched;

  /// The optional `-setKeyboardType:` hook attached. When false the bar still
  /// works; only a keyboard-type change on an already-focused input view goes
  /// unnoticed, which needs the engine to reuse one input view across fields.
  final bool keyboardTypeHookInstalled;

  /// Whether a bar can appear at all.
  bool get isUsable => installed && inputAccessoryPatched;

  @override
  String toString() => 'KeyboardAccessoryInstallResult('
      'installed: $installed, '
      'inputAccessoryPatched: $inputAccessoryPatched, '
      'keyboardTypeHookInstalled: $keyboardTypeHookInstalled)';
}
