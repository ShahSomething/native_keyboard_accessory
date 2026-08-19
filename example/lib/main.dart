import 'package:flutter/material.dart';
import 'package:native_keyboard_accessory/native_keyboard_accessory.dart';

/// The example's style at a given layout. Rebuilt rather than copied because
/// [KeyboardAccessoryStyle] is immutable and has no `copyWith`.
KeyboardAccessoryStyle _styleFor(KeyboardAccessoryLayout layout) =>
    KeyboardAccessoryStyle(
      backgroundColor: const Color(0xFFFDFCFA),
      darkBackgroundColor: const Color(0xFF234840),
      tintColor: const Color(0xFF234840),
      darkTintColor: const Color(0xFFFDFCFA),
      layout: layout,
    );

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final KeyboardAccessoryInstallResult result =
      await NativeKeyboardAccessory.instance.install(
    scope: KeyboardAccessoryScope.standard,
    style: _styleFor(KeyboardAccessoryLayout.navigationAndDone),
    labels: const KeyboardAccessoryLabels(),
  );

  runApp(ExampleApp(installResult: result));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({required this.installResult, super.key});

  final KeyboardAccessoryInstallResult installResult;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'native_keyboard_accessory',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF234840)),
        home: ExamplePage(installResult: installResult),
      );
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({required this.installResult, super.key});

  final KeyboardAccessoryInstallResult installResult;

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  KeyboardAccessoryScope _scope = KeyboardAccessoryScope.standard;
  KeyboardAccessoryLayout _layout = KeyboardAccessoryLayout.navigationAndDone;

  Future<void> _update(KeyboardAccessoryScope scope) async {
    setState(() => _scope = scope);
    // Applies immediately — including to whichever field is focused right now.
    await NativeKeyboardAccessory.instance.setScope(scope);
  }

  Future<void> _updateLayout(KeyboardAccessoryLayout layout) async {
    setState(() => _layout = layout);
    // Restyling applies immediately, including while the bar is on screen.
    await NativeKeyboardAccessory.instance.setStyle(_styleFor(layout));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Keyboard accessory')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              widget.installResult.isUsable
                  ? 'Installed. Tap a field below.'
                  : 'Not installed on this platform: ${widget.installResult}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const _Field(
              label: 'Amount (number pad — no return key)',
              keyboardType: TextInputType.number,
            ),
            const _Field(
              label: 'Phone (phone pad — no return key)',
              keyboardType: TextInputType.phone,
            ),
            const _Field(
              label: 'Email (return key works — excluded by default)',
              keyboardType: TextInputType.emailAddress,
            ),
            const _Field(
              label: 'Message (multiline — return inserts a newline)',
              keyboardType: TextInputType.multiline,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            const Text('Scope'),
            // Deliberately plain ListTiles rather than RadioGroup: this example
            // must build on the oldest Flutter the package claims to support.
            _ScopeOption(
              scope: KeyboardAccessoryScope.standard,
              title: 'standard — no-way-out fields (default)',
              selected: _scope,
              onSelected: _update,
            ),
            _ScopeOption(
              scope: KeyboardAccessoryScope.numericOnly,
              title: 'numericOnly — number pads only',
              selected: _scope,
              onSelected: _update,
            ),
            _ScopeOption(
              scope: KeyboardAccessoryScope.all,
              title: 'all — every text field',
              selected: _scope,
              onSelected: _update,
            ),
            _ScopeOption(
              scope: KeyboardAccessoryScope.none,
              title: 'none — off',
              selected: _scope,
              onSelected: _update,
            ),
            const SizedBox(height: 24),
            const Text('Layout'),
            // Plain ListTiles here too, for the same reason as Scope above.
            _LayoutOption(
              layout: KeyboardAccessoryLayout.navigationAndDone,
              title: 'navigationAndDone — chevrons and done (default)',
              selected: _layout,
              onSelected: _updateLayout,
            ),
            _LayoutOption(
              layout: KeyboardAccessoryLayout.doneOnly,
              title: 'doneOnly — done only',
              selected: _layout,
              onSelected: _updateLayout,
            ),
            _LayoutOption(
              layout: KeyboardAccessoryLayout.navigationOnly,
              title: 'navigationOnly — chevrons only',
              selected: _layout,
              onSelected: _updateLayout,
            ),
          ],
        ),
      );
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.scope,
    required this.title,
    required this.selected,
    required this.onSelected,
  });

  final KeyboardAccessoryScope scope;
  final String title;
  final KeyboardAccessoryScope selected;
  final ValueChanged<KeyboardAccessoryScope> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = scope == selected;
    return ListTile(
      onTap: () => onSelected(scope),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(title),
      selected: isSelected,
    );
  }
}

class _LayoutOption extends StatelessWidget {
  const _LayoutOption({
    required this.layout,
    required this.title,
    required this.selected,
    required this.onSelected,
  });

  final KeyboardAccessoryLayout layout;
  final String title;
  final KeyboardAccessoryLayout selected;
  final ValueChanged<KeyboardAccessoryLayout> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = layout == selected;
    return ListTile(
      onTap: () => onSelected(layout),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(title),
      selected: isSelected,
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextField(
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}
