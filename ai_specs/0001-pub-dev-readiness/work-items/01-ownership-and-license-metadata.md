---
type: Work Item
title: Ownership and license metadata
parent: ../spec.md
---

## What to build

Correct the three files that misattribute ownership to TenTwenty, so the package
declares the real owner and links to the real repository.

- `pubspec.yaml`: set `repository` and `issue_tracker` to the ShahSomething URLs.
- `ios/native_keyboard_accessory.podspec`: set `s.homepage` to the ShahSomething
  URL and replace `s.author` outright.
- `LICENSE`: rewrite the copyright line only, leaving the MIT text untouched.

No `homepage` and no `funding` field is added to `pubspec.yaml`.

## Required context

Interview Ledger records L1, L2, and L3 in `../interview-ledger.md` carry the
negative requirements for this work: the license type must not change away from
MIT, `TenTwenty` must not remain as copyright holder, and `dev@tentwenty.me`
must be replaced rather than kept alongside the new address.

The archive-level proof that no `tentwenty` string survives is requirement 8,
owned by `04-archive-exclusion.md`. Do not attempt it here: the working
directory still holds `tentwenty` strings under `example/ios/` until that Work
Item excludes the directory from the archive, so a working-directory search will
fail for reasons this Work Item cannot fix.

`pubspec.yaml` `version` and podspec `s.version` stay at `0.1.0` — changing the
package version is Out of Scope 8.

## Acceptance criteria

- [x] `pubspec.yaml` `repository` is `https://github.com/ShahSomething/native_keyboard_accessory`.
- [x] `pubspec.yaml` `issue_tracker` is `https://github.com/ShahSomething/native_keyboard_accessory/issues`.
- [x] The podspec `s.homepage` is `https://github.com/ShahSomething/native_keyboard_accessory`.
- [x] The podspec `s.author` is `{ 'ShahSomething' => 'shahsomething@yahoo.com' }`, with `dev@tentwenty.me` replaced rather than appended — no second author entry remains.
- [x] `LICENSE` carries the copyright line `Copyright (c) 2026 ShahSomething`.
- [x] `LICENSE` is still the MIT license, and its body text is otherwise unchanged — the diff touches the copyright line only.
- [x] `TenTwenty` no longer appears anywhere in `pubspec.yaml`, the podspec, or `LICENSE`.
- [x] `pubspec.yaml` has no `homepage` field and no `funding` field.
- [x] `pubspec.yaml` `version` and podspec `s.version` are both still `0.1.0`.
- [x] `flutter pub publish --dry-run` still reports zero warnings after the edits.

## Covers

- User Stories: 4
- Requirements: 1-6
- Interview Ledger: L1, L2, L3

## Blocked by

None - ready to start
