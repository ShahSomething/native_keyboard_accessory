import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_keyboard_accessory/native_keyboard_accessory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('native_keyboard_accessory');
  late List<MethodCall> log;

  setUp(() {
    log = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
      if (call.method == 'install') {
        return <Object?, Object?>{
          'installed': true,
          'inputAccessoryPatched': true,
          'keyboardTypeHookInstalled': true,
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  NativeKeyboardAccessory subject({bool platformSupported = true}) =>
      NativeKeyboardAccessory.forTesting(
        channel: channel,
        platformSupported: platformSupported,
      );

  group('install', () {
    test('reports what the platform attached', () async {
      final KeyboardAccessoryInstallResult result = await subject().install();

      expect(result.installed, isTrue);
      expect(result.inputAccessoryPatched, isTrue);
      expect(result.keyboardTypeHookInstalled, isTrue);
      expect(result.isUsable, isTrue);
    });

    test('sends scope, style and labels as one configuration', () async {
      await subject().install(
        scope: KeyboardAccessoryScope.numericOnly,
        style: const KeyboardAccessoryStyle(cornerRadius: 8, height: 44),
        labels: const KeyboardAccessoryLabels(done: 'Fertig'),
      );

      final MethodCall call =
          log.firstWhere((MethodCall c) => c.method == 'install');
      final Map<Object?, Object?> arguments =
          call.arguments as Map<Object?, Object?>;

      expect(arguments['numericKeyboards'], isTrue);
      expect(arguments['multilineFields'], isFalse);
      expect(arguments['singleLineTextFields'], isFalse);
      expect(arguments['cornerRadius'], 8);
      expect(arguments['height'], 44);
      expect(arguments['doneLabel'], 'Fertig');
    });

    test('is a no-op off iOS, and reports itself unusable', () async {
      final KeyboardAccessoryInstallResult result =
          await subject(platformSupported: false).install();

      expect(result.isUsable, isFalse);
      expect(log, isEmpty);
    });
  });

  group('setScope', () {
    test('pushes a new configuration', () async {
      final NativeKeyboardAccessory accessory = subject();
      await accessory.install();
      log.clear();

      await accessory.setScope(KeyboardAccessoryScope.all);

      final MethodCall call =
          log.firstWhere((MethodCall c) => c.method == 'setConfiguration');
      final Map<Object?, Object?> arguments =
          call.arguments as Map<Object?, Object?>;
      expect(arguments['singleLineTextFields'], isTrue);
      expect(accessory.scope, KeyboardAccessoryScope.all);
    });

    test('skips the channel when the scope is unchanged', () async {
      final NativeKeyboardAccessory accessory = subject();
      await accessory.install(scope: KeyboardAccessoryScope.standard);
      log.clear();

      await accessory.setScope(KeyboardAccessoryScope.standard);

      expect(log, isEmpty);
    });
  });

  group('onAction', () {
    Future<void> tapBarButton(String action) async {
      await TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'native_keyboard_accessory',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('onAction', action),
        ),
        (_) {},
      );
    }

    test('routes taps to a supplied handler', () async {
      final List<KeyboardAccessoryAction> seen = <KeyboardAccessoryAction>[];
      await subject().install(
        onAction: (KeyboardAccessoryAction action) {
          seen.add(action);
          return true;
        },
      );

      await tapBarButton('previous');
      await tapBarButton('next');
      await tapBarButton('done');

      expect(seen, <KeyboardAccessoryAction>[
        KeyboardAccessoryAction.previous,
        KeyboardAccessoryAction.next,
        KeyboardAccessoryAction.done,
      ]);
    });

    test('ignores an unrecognised action rather than throwing', () async {
      await subject().install(
        onAction: (KeyboardAccessoryAction action) => true,
      );

      await expectLater(tapBarButton('sideways'), completes);
    });
  });

  group('KeyboardAccessoryScope', () {
    test('standard covers exactly the fields with no way out', () {
      const KeyboardAccessoryScope scope = KeyboardAccessoryScope.standard;

      expect(scope.numericKeyboards, isTrue);
      expect(scope.multilineFields, isTrue);
      expect(scope.singleLineTextFields, isFalse);
      expect(scope.isEmpty, isFalse);
    });

    test('none is empty', () {
      expect(KeyboardAccessoryScope.none.isEmpty, isTrue);
    });

    test('value equality lets callers compare presets', () {
      expect(
        const KeyboardAccessoryScope(),
        KeyboardAccessoryScope.standard,
      );
      expect(
        KeyboardAccessoryScope.standard.copyWith(singleLineTextFields: true),
        KeyboardAccessoryScope.all,
      );
    });
  });

  group('KeyboardAccessoryStyle', () {
    test('omits colors that were not supplied', () {
      final Map<String, Object?> map = const KeyboardAccessoryStyle().toMap();

      expect(map.containsKey('backgroundColor'), isFalse);
      expect(map.containsKey('darkTintColor'), isFalse);
    });

    test('encodes colors as ARGB integers', () {
      final Map<String, Object?> map = const KeyboardAccessoryStyle(
        backgroundColor: Color(0xFF234840),
      ).toMap();

      expect(map['backgroundColor'], 0xFF234840);
    });

    test('encodes layout as its index', () {
      expect(
        const KeyboardAccessoryStyle(
          layout: KeyboardAccessoryLayout.doneOnly,
        ).toMap()['layout'],
        KeyboardAccessoryLayout.doneOnly.index,
      );
    });
  });
}
