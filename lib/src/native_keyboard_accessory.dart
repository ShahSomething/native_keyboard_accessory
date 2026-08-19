import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'keyboard_accessory_action.dart';
import 'keyboard_accessory_install_result.dart';
import 'keyboard_accessory_labels.dart';
import 'keyboard_accessory_scope.dart';
import 'keyboard_accessory_style.dart';

/// The native iOS keyboard accessory bar — the previous / next / done toolbar
/// iOS draws above the keyboard.
///
/// Unlike a Flutter overlay positioned with `MediaQuery.viewInsets`, this is a
/// real UIKit `inputAccessoryView`: it is part of the keyboard, so it animates
/// with it frame-for-frame, is included in the reported keyboard height, and
/// cannot tear or lag behind. See the README for how that is achieved and what
/// it costs.
///
/// Call [install] once during startup:
///
/// ```dart
/// await NativeKeyboardAccessory.instance.install(
///   scope: KeyboardAccessoryScope.standard,
///   labels: KeyboardAccessoryLabels(done: 'Done'),
/// );
/// ```
///
/// There is no per-field API and no widget to wrap anything in. The bar appears
/// for whichever fields fall inside [scope], decided natively from the keyboard
/// the field actually raises.
///
/// Every method is a no-op on platforms other than iOS.
class NativeKeyboardAccessory {
  NativeKeyboardAccessory._({
    MethodChannel? channel,
    bool? platformSupported,
  })  : _channel = channel ?? const MethodChannel(_channelName),
        _platformSupported = platformSupported ?? Platform.isIOS;

  /// Test seam. `dart:io` `Platform` cannot be faked, so the platform guard is
  /// injected rather than probed.
  @visibleForTesting
  factory NativeKeyboardAccessory.forTesting({
    required MethodChannel channel,
    bool platformSupported = true,
  }) =>
      NativeKeyboardAccessory._(
        channel: channel,
        platformSupported: platformSupported,
      );

  static const String _channelName = 'native_keyboard_accessory';

  /// The shared instance. The bar is a single app-wide UIKit object, so
  /// there is deliberately no way to create a second one.
  static final NativeKeyboardAccessory instance = NativeKeyboardAccessory._();

  final MethodChannel _channel;
  final bool _platformSupported;

  KeyboardAccessoryScope _scope = KeyboardAccessoryScope.standard;
  KeyboardAccessoryStyle _style = const KeyboardAccessoryStyle();
  KeyboardAccessoryLabels _labels = const KeyboardAccessoryLabels();
  KeyboardAccessoryActionHandler? _onAction;

  KeyboardAccessoryInstallResult _installResult =
      KeyboardAccessoryInstallResult.unsupported;

  bool _installed = false;

  /// Last state pushed to the native side, so a [FocusManager] notification
  /// that changed nothing relevant does not cost a channel hop.
  ({bool canPrevious, bool canNext})? _lastNavigationState;

  /// Which fields currently show the bar.
  KeyboardAccessoryScope get scope => _scope;

  /// The bar's current appearance.
  KeyboardAccessoryStyle get style => _style;

  /// The bar's current VoiceOver labels.
  KeyboardAccessoryLabels get labels => _labels;

  /// What the native install attached. Meaningful only after [install].
  KeyboardAccessoryInstallResult get installResult => _installResult;

  /// Whether [install] has run and the bar can appear.
  bool get isInstalled => _installed && _installResult.isUsable;

  /// Installs the native patch and starts observing focus. Idempotent —
  /// calling again updates the configuration and returns the existing result.
  ///
  /// The returned [KeyboardAccessoryInstallResult] says what actually attached;
  /// check [KeyboardAccessoryInstallResult.isUsable] if you want to detect a
  /// Flutter version this package cannot support rather than silently showing
  /// no bar.
  Future<KeyboardAccessoryInstallResult> install({
    KeyboardAccessoryScope scope = KeyboardAccessoryScope.standard,
    KeyboardAccessoryStyle style = const KeyboardAccessoryStyle(),
    KeyboardAccessoryLabels labels = const KeyboardAccessoryLabels(),
    KeyboardAccessoryActionHandler? onAction,
  }) async {
    _scope = scope;
    _style = style;
    _labels = labels;
    _onAction = onAction;

    if (!_platformSupported) {
      return _installResult;
    }

    if (!_installed) {
      _installed = true;
      _channel.setMethodCallHandler(_handleNativeCall);
      FocusManager.instance.addListener(_onFocusChanged);
    }

    final Map<Object?, Object?>? response =
        await _invoke<Map<Object?, Object?>>('install', _configurationMap());
    _installResult = KeyboardAccessoryInstallResult.fromMap(response);

    _pushNavigationState(force: true);
    return _installResult;
  }

  /// Stops observing focus and hides the bar.
  ///
  /// The native method implementations are deliberately left in place —
  /// restoring an original implementation is not safe once another party may
  /// have patched the same method afterwards. The bar simply stops being
  /// returned, so this is reversible by calling [install] again.
  Future<void> uninstall() async {
    if (!_installed) return;
    _installed = false;
    FocusManager.instance.removeListener(_onFocusChanged);
    _channel.setMethodCallHandler(null);
    _lastNavigationState = null;
    await _invoke<void>('setSuppressed', true);
  }

  /// Changes which fields show the bar. Takes effect on the next focus, and
  /// immediately for a field that is focused right now.
  Future<void> setScope(KeyboardAccessoryScope scope) async {
    if (scope == _scope) return;
    _scope = scope;
    await _pushConfiguration();
    _pushNavigationState(force: true);
  }

  /// Restyles the bar. Applies immediately, including while it is on screen.
  Future<void> setStyle(KeyboardAccessoryStyle style) async {
    if (style == _style) return;
    _style = style;
    await _pushConfiguration();
  }

  /// Replaces the VoiceOver labels. Call this when the app's locale changes.
  Future<void> setLabels(KeyboardAccessoryLabels labels) async {
    if (labels == _labels) return;
    _labels = labels;
    await _pushConfiguration();
  }

  /// Overrides what the buttons do. See [KeyboardAccessoryActionHandler].
  void setActionHandler(KeyboardAccessoryActionHandler? onAction) {
    _onAction = onAction;
  }

  Map<String, Object?> _configurationMap() => <String, Object?>{
        ..._scope.toMap(),
        ..._style.toMap(),
        ..._labels.toMap(),
      };

  Future<void> _pushConfiguration() =>
      _invoke<void>('setConfiguration', _configurationMap());

  Future<Object?> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onAction') return null;

    final KeyboardAccessoryAction? action =
        KeyboardAccessoryAction.tryParse(call.arguments);
    if (action == null) return null;

    if (_onAction?.call(action) ?? false) return null;

    final FocusNode? node = FocusManager.instance.primaryFocus;
    if (node == null) return null;

    switch (action) {
      case KeyboardAccessoryAction.previous:
        node.previousFocus();
      case KeyboardAccessoryAction.next:
        node.nextFocus();
      case KeyboardAccessoryAction.done:
        node.unfocus();
    }
    return null;
  }

  void _onFocusChanged() => _pushNavigationState();

  void _pushNavigationState({bool force = false}) {
    if (!_installed || _scope.isEmpty) return;

    final FocusNode? node = FocusManager.instance.primaryFocus;
    final List<FocusNode> siblings =
        node == null ? const <FocusNode>[] : _traversalSiblings(node);
    final int index = node == null ? -1 : siblings.indexOf(node);

    final state = (
      canPrevious: index > 0,
      canNext: index >= 0 && index < siblings.length - 1,
    );
    if (!force && state == _lastNavigationState) return;
    _lastNavigationState = state;

    _invoke<void>('setNavigationState', <String, Object?>{
      'canPrevious': state.canPrevious,
      'canNext': state.canNext,
    });
  }

  /// Focusable peers of [node] within its nearest scope, in tree order.
  ///
  /// [FocusNode.traversalDescendants] already drops nodes that skip traversal
  /// or cannot take focus, but it yields depth-first tree order rather than the
  /// active `FocusTraversalPolicy`'s order — the framework exposes no way to ask
  /// a policy "is there a next node?" without actually moving focus. The two
  /// agree for the vertical field stacks this bar is used on; where they
  /// diverge the cost is only a chevron shown enabled that turns out to be a
  /// no-op, or disabled when it could have moved. It never causes a wrong jump,
  /// because the tap itself always goes through the real policy.
  List<FocusNode> _traversalSiblings(FocusNode node) {
    final FocusScopeNode? scope = node.nearestScope;
    if (scope == null) return const <FocusNode>[];
    return scope.traversalDescendants.toList(growable: false);
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (!_platformSupported) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      // The bar is a convenience. A misbehaving platform side must never break
      // the host app's text entry.
      debugPrint('native_keyboard_accessory: $method failed — ${error.message}');
      return null;
    } on MissingPluginException {
      // Plugin not registered (unit tests, an unsupported embedder). Silent by
      // design — this is an expected configuration, not a fault.
      return null;
    }
  }
}
