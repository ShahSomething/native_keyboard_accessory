---
type: Work Item
title: Flutter 3.47.0 verification, README compatibility claim, and screenshot gallery
parent: ../spec.md
---

## What to build

One simulator session on Flutter 3.47.0 that both proves the engine patch still
works and produces the four gallery images, then the README and `pubspec.yaml`
wiring that publishes both results.

1. **Layout switcher in the example.** Add a runtime `KeyboardAccessoryLayout`
   switcher to `example/lib/main.dart` — `navigationAndDone` (default),
   `doneOnly`, `navigationOnly` — driven through the existing
   `NativeKeyboardAccessory.instance.setStyle`. This is the resolution of the
   Spec's Open Question 2, and it makes the `doneOnly` image reproducible.

2. **Verification session.** Run the example on the booted `iPhone 17 Pro Max`
   (iOS 26.5) simulator on Flutter 3.47.0. Read the real
   `KeyboardAccessoryInstallResult` and record the observed values of `installed`,
   `inputAccessoryPatched`, and `keyboardTypeHookInstalled`. Capture
   `flutter --version` in the **same session**.

3. **README compatibility claim.** Replace the closing paragraph of the
   `## Engine coupling — read this before shipping` section — the two-line
   sentence beginning *"Verified against Flutter 3.41.9 (engine `9161402dc0`)"* —
   in full. The replacement names Flutter 3.47.0 and its engine revision, taken
   from the same-session `flutter --version` capture, states that versions below
   it down to the declared floor are permitted but unverified, and names
   `isUsable` as the runtime canary.

4. **Four images in `doc/images/`.**
   - `bar_light.webp` — numeric keypad with the bar in light mode.
   - `bar_dark.webp` — the same in dark mode.
   - `bar_default_style.webp` — the zero-config `const KeyboardAccessoryStyle()`
     appearance: unfilled pill, `UIColor.labelColor` icons. This is the
     resolution of the Spec's Open Question 1.
   - `bar_done_only.webp` — the `doneOnly` layout.

   Open Question 2 authorized a **layout** switcher only, and Out of Scope 10
   bars further growth of the example, so reach the zero-config style for
   `bar_default_style.webp` with a temporary local edit to the `style:` argument
   of `install()` and revert it after capture. Ship no style switcher.

5. **Crop and encode.** Crop each to approximately the bottom 45% of the frame —
   1320x2868 source to 1320x1290 — so the bar plus keyboard is the subject
   rather than a thin sliver. Encode WebP at approximately quality 85, targeting
   roughly 40-80 KB each, using Python Pillow.

6. **Wire both surfaces from one file set.** Add a `screenshots:` section to
   `pubspec.yaml` with a `path` and a `description` per entry, and a new
   `## Screenshots` section to `README.md` placed immediately after the opening
   `iOS only.` paragraph and before `## Why you might need it`, referencing the
   same files by relative path.

7. **Review.** Present all four images to the user. Framing, crop, and colour
   quality are subjective; recapture anything rejected rather than declaring it
   final.

## Required context

`NativeKeyboardAccessory.instance.setStyle` at
`lib/src/native_keyboard_accessory.dart:154` already applies a style at runtime,
so the switcher needs no new plumbing. `KeyboardAccessoryLayout` is declared at
`lib/src/keyboard_accessory_style.dart:6` and `layout` defaults to
`navigationAndDone` at line 40.

`example/lib/main.dart` installs the teal `#234840` / cream `#FDFCFA` style as
its default in **both** appearances — `backgroundColor: #FDFCFA` with
`tintColor: #234840` in light, `darkBackgroundColor: #234840` with
`darkTintColor: #FDFCFA` in dark. That overlap is why Open Question 1 resolved
the third image toward the zero-config default rather than the teal style.

`example/lib/main.dart` carries an existing comment stating its `ListTile`
options are deliberately plain rather than `RadioGroup`, because the example must
build on the oldest Flutter the package claims to support. The layout switcher
must follow that same pattern.

README anchors: the `iOS only.` paragraph is at `README.md:13-14`,
`## Why you might need it` is at `README.md:16`, and the claim being replaced is
the last paragraph of the `## Engine coupling` section, spanning two source
lines.

Image tooling, measured in Spec Note 9: `sips -s format webp` fails with
`Can't write format: org.webmproject.webp`; `cwebp` and ImageMagick are not
installed; Python `PIL 11.3.0` reports `features.check('webp') == True` and
successfully wrote a 1320x1290 quality-85 WebP.

The dry-run validates only that `screenshots:` paths exist — not description
length and not image format. Description length must be checked by explicit
character count. If pub.dev rejects WebP server-side, which the dry-run cannot
rule out, the fallback is PNG at reduced pixel width rather than full-frame PNG
(Technical Decision 4).

The README's relative image paths only resolve on pub.dev once the repository is
public and pushed to `main`. Both are owned by `05-gates-push-and-handover.md`,
not this Work Item. Do not substitute `raw.githubusercontent.com` URLs to work
around it.

Testing Strategy 1, 4, 5, and 7: TDD does not apply and no new automated tests
are required. The compatibility check is manual simulator verification and cannot
be faked, because its purpose is to observe how the real engine responds to the
runtime patch. The capture session doubles as its evidence — the images are proof
the bar rendered on 3.47.0. The layout switcher is user-facing example Dart with
no test requirement, but it falls under requirement 21's analyzer gate.

## Acceptance criteria

- [x] `example/lib/main.dart` gains a layout switcher offering `KeyboardAccessoryLayout.navigationAndDone`, `.doneOnly`, and `.navigationOnly`, applied at runtime through `NativeKeyboardAccessory.instance.setStyle`.
- [x] The switcher follows the file's existing plain-`ListTile` pattern rather than introducing `RadioGroup`.
- [x] `flutter analyze` run from inside `example/` still reports zero issues after the switcher is added.
- [x] The example app is run on the booted `iPhone 17 Pro Max` (iOS 26.5) simulator on Flutter 3.47.0.
- [x] The observed values of `installed`, `inputAccessoryPatched`, and `keyboardTypeHookInstalled` from the real `KeyboardAccessoryInstallResult` are recorded and reported.
- [x] `flutter --version` is captured in that same session, and the framework, engine, and Dart revisions written into the README come from that capture rather than from Spec Note 7.
- [x] The two-line sentence beginning *"Verified against Flutter 3.41.9"* at the end of `## Engine coupling — read this before shipping` is replaced in full, with no fragment of it left behind.
- [x] The replacement names Flutter 3.47.0 and its engine revision, states that versions below it down to the declared floor are permitted but unverified, and names `isUsable` as the runtime canary.
- [x] `pubspec.yaml` still declares `sdk: ^3.6.0` and `flutter: '>=3.27.0'` — the floor is not narrowed.
- [x] The README claims verification for Flutter 3.47.0 only, and for no version not actually exercised.
- [x] If the 3.47.0 verification fails or cannot be completed, that outcome is reported and the README version number is left unedited rather than changed to match.
- [x] `doc/images/` contains exactly `bar_light.webp`, `bar_dark.webp`, `bar_default_style.webp`, and `bar_done_only.webp`.
- [x] `bar_light.webp` shows the numeric keypad with the bar in light mode, and `bar_dark.webp` shows the same in dark mode.
- [x] `bar_default_style.webp` shows the zero-config `const KeyboardAccessoryStyle()` appearance — unfilled pill with `UIColor.labelColor` icons — and is visually distinct from `bar_light.webp` and `bar_dark.webp`.
- [x] `bar_done_only.webp` shows the `doneOnly` layout.
- [x] The temporary edit used to reach `const KeyboardAccessoryStyle()` is reverted, and no style switcher ships in `example/lib/main.dart`.
- [x] Each image is cropped to approximately the bottom 45% of the frame — 1320x2868 source cropped to 1320x1290 — showing bar plus keyboard.
- [x] Each image is WebP encoded with Python Pillow at approximately quality 85, and each file is roughly 40-80 KB, with the four measured sizes reported.
- [x] `pubspec.yaml` gains a `screenshots:` section with one entry per file, each carrying both a `path` and a `description`.
- [x] Every `description` is between 10 and 160 characters, reported as an explicit per-entry character count rather than assumed from the dry-run passing.
- [x] `README.md` gains a `## Screenshots` section placed immediately after the opening `iOS only.` paragraph and before `## Why you might need it`.
- [x] The `## Screenshots` section references the same four files by relative path, single-sourced with the `screenshots:` entries.
- [x] No `raw.githubusercontent.com` URL appears anywhere in `README.md`.
- [x] All four images are presented to the user for review, and any image the user rejects is recaptured rather than declared final.

## Covers

- User Stories: 2, 3
- Requirements: 9-18
- Testing Strategy: 1, 4, 5, 7
- Interview Ledger: L4, L6, L7
- Technical Decisions: 1, 2, 3, 4
- Open Questions: 1, 2 (both resolved before decomposition)

## Blocked by

- `02-analyzer-hygiene-and-example-floor.md` — the capture session and the layout
  switcher must run against the example's final dependency resolution and
  analyzer state, so the SDK floor and `flutter_lints` widening land first.
