## 0.1.0

Initial release.

- Native UIKit `inputAccessoryView` (previous / next / done) for Flutter text
  fields on iOS, attached to the engine's own input view rather than drawn as a
  Flutter overlay.
- `KeyboardAccessoryScope` selects which fields get the bar, as three
  independent switches: keyboards with no return key, multi-line fields whose
  return key inserts a newline, and single-line fields whose return key already
  works. Scope changes apply live, including to the field focused right now.
- `KeyboardAccessoryStyle` for colors (with separate dark-mode values), metrics,
  continuous corner curvature, shadow, and three button layouts.
- `KeyboardAccessoryLabels` for VoiceOver, supplied from Dart so they follow the
  host app's localization.
- Default button behaviour is focus traversal; override it with
  `KeyboardAccessoryActionHandler`.
- `install()` returns a `KeyboardAccessoryInstallResult` reporting exactly what
  attached, so a host can detect an unsupported engine at runtime.
