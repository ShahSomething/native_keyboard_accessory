---
type: Work Item
title: Analyzer hygiene and example SDK floor alignment
parent: ../spec.md
---

## What to build

Clear the two info-level `unnecessary_import` lints and align the example's
declared SDK floor with the package it demonstrates, so both packages analyze
clean at zero issues.

- Remove the unnecessary `package:flutter/foundation.dart` import at
  `lib/src/native_keyboard_accessory.dart:3`.
- Remove the unnecessary `dart:ui` import at
  `test/native_keyboard_accessory_test.dart:1`.
- In `example/pubspec.yaml`, change `sdk: ^3.11.5` to `sdk: ^3.6.0` **and**
  widen the `flutter_lints: ^6.0.0` dev dependency to `'>=5.0.0 <7.0.0'`.
- Get `flutter analyze` to zero issues in the package root and in `example/`,
  and keep `flutter test` green.

## Required context

Relaxing the example's SDK constraint alone leaves the goal unmet, and fails
silently: `flutter_lints 6.0.0` declares `sdk: ^3.8.0`, so the example would
still fail to resolve on Dart 3.6, while every local gate would pass because pub
solves against the local Dart 3.13.0. `flutter_lints 5.0.0` declares
`sdk: ^3.5.0`, so the widened range resolves to 6.x today and 5.x at the
declared floor. Both halves of requirement 22 are required.

`flutter analyze` at the package root analyzes only the package — the example is
a separate package with its own `analysis_options.yaml` — so the example needs
its own run from inside `example/`.

Spec Note 5: running `flutter analyze` during exploration caused the tool to add
platform and build exclusions to the root `analysis_options.yaml`, and that
change is retained. Expect the same automatic edit to
`example/analysis_options.yaml` when this Work Item's change triggers a fresh
`flutter pub get` there. Retain it rather than reverting it.

The root `pubspec.yaml` also pins `flutter_lints: ^6.0.0` alongside
`sdk: ^3.6.0`. The Spec does not require changing it. Leave it alone.

Flutter 3.27 is not installed locally (Spec Note 6), so the floor claim cannot be
verified empirically here. Do not attempt it.

Testing Strategy 1, 2, and 3: this is a packaging and metadata change, so TDD
does not apply and no new tests are required. The two import removals are covered
by the existing 13-test suite in `test/native_keyboard_accessory_test.dart`,
which must stay green with no changes to test expectations. The existing Test Seam
is `NativeKeyboardAccessory.forTesting`; no new seam is needed.

## Acceptance criteria

- [x] `lib/src/native_keyboard_accessory.dart` no longer imports `package:flutter/foundation.dart`.
- [x] `test/native_keyboard_accessory_test.dart` no longer imports `dart:ui`.
- [x] `example/pubspec.yaml` declares `sdk: ^3.6.0`.
- [x] `example/pubspec.yaml` declares `flutter_lints: '>=5.0.0 <7.0.0'` in `dev_dependencies`.
- [x] `flutter pub get` in `example/` resolves, and the resolved `flutter_lints` version on the current toolchain is a 6.x release.
- [x] `flutter analyze` at the package root reports zero issues, including zero info-level lints, with real output reported.
- [x] `flutter analyze` run from inside `example/` reports zero issues, including zero info-level lints, with real output reported.
- [x] `flutter test` passes all 13 tests, with no changes to any test expectation.
- [x] Any automatic platform or build exclusions `flutter analyze` adds to `example/analysis_options.yaml` are retained rather than reverted.
- [x] The root `pubspec.yaml` `flutter_lints` constraint is unchanged.

## Covers

- Requirements: 19-22
- Testing Strategy: 1, 2, 3

## Blocked by

None - ready to start
