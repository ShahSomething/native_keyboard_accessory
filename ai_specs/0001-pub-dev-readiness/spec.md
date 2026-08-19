---
type: Spec
title: pub.dev Readiness For native_keyboard_accessory
---

## Problem

`native_keyboard_accessory` already passes `flutter pub publish --dry-run` with zero warnings, ships 13 passing tests, and documents every public member via the `public_member_api_docs` lint. It is not, however, ready to publish, because three things it asserts about itself are untrue, one is missing entirely, and the repository it points at is unreachable.

1. **Ownership is misattributed.** `pubspec.yaml` declares `repository` and `issue_tracker` at `github.com/tentwenty/native_keyboard_accessory`, the podspec declares the same `homepage` plus author `TenTwenty <dev@tentwenty.me>`, and `LICENSE` asserts `Copyright (c) 2026 TenTwenty`. The actual owner is ShahSomething and the code will live at `github.com/ShahSomething/native_keyboard_accessory`. pub.dev renders `repository` as a live link and uses it for repository verification, so this publishes a broken link, and an MIT grant naming the wrong holder is a defective license rather than a cosmetic error.

2. **The target repository is private.** `gh repo view ShahSomething/native_keyboard_accessory` reports `visibility: PRIVATE`, and the unauthenticated GitHub API returns `Not Found`. Correcting the URL is not enough: a private repository produces the same 404 for evaluators, and pub.dev cannot resolve the relative README image paths this Spec introduces, so the screenshot gallery would render as broken images on the package page.

3. **The compatibility claim is stale.** The closing paragraph of the README's `## Engine coupling — read this before shipping` section states *"Verified against Flutter 3.41.9 (engine `9161402dc0`)"*. The current toolchain is Flutter 3.47.0 — six minor versions on. For a package whose entire risk surface is one `NSClassFromString(@"FlutterTextInputView")` lookup against an engine-internal class, that sentence is the most misleading line on the package page.

4. **The package has no version control at all.** There is no `.git` directory. The target remote exists and is completely empty, so nothing can be pushed, linked, or verified against a commit.

5. **A visual package ships no visuals.** The whole proposition is a bar above the keyboard, and the package page would render no image of it.

## Proposed Outcome

A publish-ready package at a pushed, publicly reachable GitHub repository: ownership metadata that matches reality, a compatibility claim backed by a verification actually performed on Flutter 3.47.0, a screenshot gallery on both pub.dev and the README, a clean analyzer, and an archive that carries no internal workflow files and no build output. Publishing itself stays in the user's hands.

## User Stories

1. As someone evaluating the package on pub.dev, I can click the repository link and reach the real source, so I can audit a package that patches engine internals before depending on it.
2. As someone evaluating the package on pub.dev, I can see what the accessory bar actually looks like in light and dark mode without cloning and building the example.
3. As someone deciding whether to depend on the package, I can read which Flutter version it was genuinely verified against, and understand what happens on versions below that, so I can judge the engine-coupling risk myself.
4. As the package owner, I hold the copyright in my own name under MIT, with no residual references to a company that does not own the work.
5. As the package owner, I can review everything in a pushed GitHub repository — including the Spec and Interview Ledger that produced the work — and run one publish command myself, rather than discovering an irreversible upload already happened.
6. As a contributor cloning the repository, internal workflow artifacts and agent guidance stay available in git while staying out of the published archive that package consumers download.

## Requirements

### Ownership and license metadata

1. `pubspec.yaml` `repository` must be `https://github.com/ShahSomething/native_keyboard_accessory`. [L1]
2. `pubspec.yaml` `issue_tracker` must be `https://github.com/ShahSomething/native_keyboard_accessory/issues`. [L1]
3. The podspec `s.homepage` must be `https://github.com/ShahSomething/native_keyboard_accessory`. [L1]
4. The podspec `s.author` must be `{ 'ShahSomething' => 'shahsomething@yahoo.com' }`, replacing `dev@tentwenty.me` rather than appending to it. [L3]
5. `LICENSE` must remain the MIT license text with the copyright line `Copyright (c) 2026 ShahSomething`. The license type must not change and `TenTwenty` must not remain as holder. [L2]
6. No `homepage` and no `funding` field is added to `pubspec.yaml`. [L3]
7. `github.com/ShahSomething/native_keyboard_accessory` must be publicly readable before `flutter pub publish` is run. Verified by an **unauthenticated** request — `curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/ShahSomething/native_keyboard_accessory` returning `200`, not by `git ls-remote` or `gh`, both of which succeed against a private repository using cached credentials. Flipping visibility is the user's action; this work must report the current state and block the handover in requirement 28 until it is public. [L1]
8. After the change, no occurrence of `TenTwenty`, `tentwenty`, or `dev@tentwenty.me` remains anywhere in the published archive. Verified by unpacking the archive the dry-run produces and searching it, not by searching the working directory — the working directory retains `tentwenty` strings in `example/ios/`, which requirement 24 excludes from the archive. [L1] [L3]

### Compatibility claim

9. The engine patch must be exercised on Flutter 3.47.0 by running the example app on an iOS simulator and reading the real `KeyboardAccessoryInstallResult`, recording the observed values of `installed`, `inputAccessoryPatched`, and `keyboardTypeHookInstalled`. `flutter --version` must be captured in the **same session**, and the framework, engine, and Dart revisions written into the README must come from that capture rather than from the Notes section of this Spec. [L4]
10. The closing paragraph of the README's `## Engine coupling — read this before shipping` section — currently the two-line sentence beginning *"Verified against Flutter 3.41.9"* — must be replaced with a claim naming Flutter 3.47.0 and its engine revision, and stating that versions below it down to the declared floor are permitted but unverified, with `isUsable` as the runtime canary. Replace the whole sentence; it spans two source lines. [L4]
11. The declared support floor must stay `sdk: ^3.6.0` and `flutter: '>=3.27.0'`. It must not be narrowed. [L4]
12. The README must not claim verification for any Flutter version not actually exercised. If the 3.47.0 verification fails or cannot be completed, that outcome must be reported rather than the number being edited to match. [L4]

### Screenshots

13. Four images must be produced in `doc/images/`, named `bar_light.webp`, `bar_dark.webp`, `bar_default_style.webp`, and `bar_done_only.webp`: the numeric keypad with the bar in light mode; the same in dark mode; the third image as resolved by Open Question 1; and the `doneOnly` layout. Open Questions 1 and 2 are **blocking for this requirement** and must be resolved before capture. [L6] [L7]
14. Images must be cropped to approximately the bottom 45% of the frame, showing bar plus keyboard, so the bar is the subject rather than a thin sliver. For the iPhone 17 Pro Max simulator that is a 1320x2868 source cropped to 1320x1290. [L7]
15. Images must be WebP at approximately quality 85, targeting roughly 40-80 KB each, keeping the total published archive well under the threshold in requirement 29 rather than the ~3 MB four full-frame PNGs would cost. Encode with Python Pillow, which is installed with WebP support; `sips` cannot write WebP on this machine and neither `cwebp` nor ImageMagick is installed. [L7]
16. `pubspec.yaml` must gain a `screenshots:` section referencing these files, each entry carrying both a `path` and a `description`. Each `description` must be between 10 and 160 characters, **verified by explicit character count** — the dry-run validates only that the paths exist, not description length or image format. [L7]
17. The README must reference the same files by relative path, in a new `## Screenshots` section placed immediately after the opening `iOS only.` paragraph and before `## Why you might need it`, single-sourced with the `screenshots:` entries. No `raw.githubusercontent.com` absolute URLs. [L7]
18. The images must be presented to the user for review. Framing, crop, and colour quality are subjective and any rejected image is expected to be recaptured rather than declared final. [L7]

### Analyzer and hygiene

19. Remove the unnecessary `package:flutter/foundation.dart` import at `lib/src/native_keyboard_accessory.dart:3`.
20. Remove the unnecessary `dart:ui` import at `test/native_keyboard_accessory_test.dart:1`.
21. `flutter analyze` must report zero issues, including zero info-level lints, in **both** the package root and `example/`. Run at the package root it analyzes only the package — the example is a separate package with its own `analysis_options.yaml` — so the example needs its own run. This matters because requirement 22, and Open Question 2 if resolved toward a layout switcher, both change files under `example/`.
22. `example/pubspec.yaml` currently pins `sdk: ^3.11.5` while the package itself permits `^3.6.0`. It must become `sdk: ^3.6.0`, **and** its `flutter_lints: ^6.0.0` dev dependency must widen to `'>=5.0.0 <7.0.0'`. Relaxing the SDK constraint alone leaves the goal unmet: `flutter_lints 6.0.0` declares `sdk: ^3.8.0`, so the example would still fail to resolve on Dart 3.6 — and it would fail silently, because pub solves against the local Dart 3.13.0 and every gate would pass. `flutter_lints 5.0.0` declares `sdk: ^3.5.0`, so the widened range resolves to 6.x today and 5.x on the declared floor. The example is what a reader builds to check compatibility on an older Flutter, so it must not constrain the SDK more tightly than the package it demonstrates.
23. Internal workflow artifacts and agent guidance must not enter the published archive, while remaining tracked in git. The exclusion mechanism is a root `.pubignore`, and it **must be written as a superset of the publish-relevant `.gitignore` entries**, because `.pubignore` replaces `.gitignore` for `pub publish` rather than adding to it. Measured: a `.pubignore` listing only the new exclusions produced a **27 MB** archive with **0 warnings**, because `build/` and `example/build/` stopped being ignored. The file must therefore carry `build/`, `.dart_tool/`, `.flutter-plugins-dependencies`, `coverage/`, `**/doc/api/`, `pubspec.lock`, `*.iml`, `*.ipr`, `*.iws`, `.idea/`, `.DS_Store`, plus the new entries in requirements 24 and 25 and `ai_specs/` and `.act/`. `ai_specs/` must stay out of `.gitignore` so the Spec and Interview Ledger are committed and pushed. [L8]
24. `example/ios/` must be excluded from the published archive. It carries no package source, it is regenerable, and it is the sole remaining source of `tentwenty` strings in the archive — `example/ios/Runner.xcodeproj/project.pbxproj` contains `PRODUCT_BUNDLE_IDENTIFIER = com.tentwenty.nativeKeyboardAccessoryExample` at six sites and `DEVELOPMENT_TEAM = PTEE8T35KX` at three, so excluding it is what makes requirement 8 satisfiable. `example/lib/main.dart`, `example/pubspec.yaml`, `example/README.md`, and `example/analysis_options.yaml` must continue to ship, so pub.dev's example tab still works. The directory stays in git.
25. ACT created `CLAUDE.md` as a symlink to `AGENTS.md`, and both currently ship in the archive with the symlink resolving to a duplicate file. Both must be excluded from the published archive and both must remain in git: agent guidance serves contributors, not package consumers, and `CLAUDE.md` must keep working as the Claude Code entry point. [L8]

### Version control and handover

26. Initialise a git repository with `git init -b main`, commit the work as a single initial commit, add `https://github.com/ShahSomething/native_keyboard_accessory.git` as `origin`, and push with upstream tracking set. The branch name must be `main` explicitly: `init.defaultBranch` is unset locally so `git init` would otherwise produce `master`, the remote has no default branch yet so the first pushed branch becomes the default, and pub.dev resolves the relative README image paths in requirement 17 against `repository` plus that default branch. The remote is currently empty, so this is a first push with no overwrite risk. [L5]
27. `flutter pub publish` must not be executed, and pub.dev credentials must not be authenticated or altered. [L5]
28. The exact publish command must be surfaced to the user on completion so they can run it themselves, together with the two preconditions that are the user's own to satisfy: the repository must be public (requirement 7), and the version decision in Open Question 3 must be settled first, because choosing `1.0.0` changes four files and would make an already-surfaced `0.1.0` command stale. [L5] [L9]

### Verification gates

29. All of the following must pass and be reported with real output before the work is called done:
    - `flutter analyze` at the package root — zero issues.
    - `flutter analyze` in `example/` — zero issues.
    - `flutter test` — all tests green.
    - `flutter pub publish --dry-run` — zero warnings.
    - The resulting archive size, which must not exceed **400 KB**. A size report alone is not a gate: the 27 MB archive measured in requirement 23 passed the dry-run with zero warnings.
    - The unpacked-archive `tentwenty` search from requirement 8.
    - The character count of each `screenshots:` description from requirement 16.
    - The unauthenticated repository-visibility check from requirement 7, reported even if it fails, since flipping visibility is the user's action.

## Technical Decisions

1. The `>=3.27.0` floor is retained deliberately rather than tightened. `Color.toARGB32()` in `lib/src/keyboard_accessory_style.dart` is the API that replaced deprecated `Color.value` in Flutter 3.27, so 3.27 is a real API boundary. Because `NKATextInputPatch.m` resolves the engine class through `NSClassFromString` and skips the patch when absent, an unverified older version degrades to "no bar" rather than crashing — which makes a wide floor defensible provided the README says so plainly. [L4]
2. Verification is deliberately narrowed to 3.47.0 rather than the three-version matrix originally recommended, accepting the `isUsable` canary as the compatibility story for earlier versions. FVM has 3.32.5 through 3.47.0 installed locally, so a wider matrix remains cheap to add later. [L4]
3. Screenshots are stored once in `doc/images/` and referenced by relative path from both the README and `pubspec.yaml` `screenshots:`. These are two different delivery paths, not one: the `screenshots:` gallery is served from the archive, while the inline README images are served from GitHub via pub.dev's relative-link rewriting against `repository` and its default branch. One file set serves both surfaces with no URLs that can rot, but the README path only works once requirement 7 (public) and requirement 26 (pushed to `main`) both hold — which is why the push precedes the handover rather than following it. [L7]
4. WebP over PNG is a size decision, not an aesthetic one: raw iPhone 17 Pro Max simulator captures are 1320x2868 at 3x, and four of them would grow a 25 KB archive roughly 120-fold. The encoder is Python Pillow because it is the only WebP-capable tool present. If pub.dev rejects WebP server-side — a possibility the dry-run cannot rule out, since it validates only that screenshot paths exist — the fallback is PNG at reduced pixel width rather than full-frame PNG. [L7]
5. Publishing is excluded from this work because it is irreversible in three distinct ways: the package name is claimed permanently, version `0.1.0` can never be re-uploaded, and the upload binds the package to whichever pub.dev account is authenticated — an identity that just changed hands. The push, by contrast, is fully reversible. [L5]
6. ACT workflow storage is local markdown under `ai_specs` with guidance in `AGENTS.md`. Because these live inside the package directory, they create the exclusion requirement in requirement 23. [L8]
7. Archive exclusion uses `.pubignore` rather than `.gitignore` because the two goals differ: the Spec, Interview Ledger, and agent guidance must be **in git and out of the tarball**. `.gitignore` cannot express that — anything it excludes is also absent from the pushed repository. Measured facts behind this choice: `pub publish` honours `.gitignore` even with no git repository present, so the current 61 KB archive is `.gitignore`-filtered already; and where a root `.pubignore` exists it supersedes `.gitignore` entirely, which is why requirement 23 mandates a superset rather than a delta. [L8]

## Testing Strategy

1. This is a packaging, documentation, and metadata change, so TDD does not apply. No new Dart behaviour is specified, and no new unit, widget, or robot tests are required. [L4]
2. The two import removals are the only code edits to the package. They are covered by the existing 13-test suite in `test/native_keyboard_accessory_test.dart`, which must stay green with no modifications to test expectations.
3. The existing Test Seam is `NativeKeyboardAccessory.forTesting`, which injects the `MethodChannel` and the platform guard because `dart:io Platform` cannot be faked. Prefer it; no new seam is needed for this work.
4. The Flutter 3.47.0 compatibility check is **manual simulator verification, not an automated test**. It cannot be faked, because its entire purpose is to observe how the real engine responds to the runtime patch. Its evidence is the observed `KeyboardAccessoryInstallResult` field values plus the same-session `flutter --version` output, which must be recorded in the README claim and reported to the user.
5. Screenshot capture doubles as the verification vehicle: the same simulator session that confirms `isUsable` produces the images, so the images are evidence the bar rendered on 3.47.0.
6. Archive composition is verified by unpacking what the dry-run builds, not by inspecting the working directory. Requirements 8, 23, 24, and 25 all describe archive contents that differ from the working tree.
7. If Open Question 2 is resolved toward a layout switcher in the example, that is new user-facing Dart in `example/lib/main.dart`. It carries no test requirement — the example is not published behaviour — but it does fall under requirement 21's analyzer gate.
8. No automated test may depend on network access, a real device, or credentials. The two exceptions are explicit, manual, and reported: the simulator verification in requirement 9, and the unauthenticated repository-visibility check in requirement 7.

## Out of Scope

1. Running `flutter pub publish`. [L5]
2. Changing the license type away from MIT. [L2]
3. Narrowing the `>=3.27.0` support floor. [L4]
4. Verifying Flutter versions other than 3.47.0. [L4]
5. Adding Android or other platform implementations. The package is iOS-only by design and documents why.
6. Restoring original method implementations in `uninstall()`. The README already explains why this is deliberately not done.
7. Adding a `.github/workflows` CI job. [L10]
8. Changing the package version. [L9]
9. Changing the example's iOS bundle identifier or its `DEVELOPMENT_TEAM`. Requirement 24 removes `example/ios/` from the archive, so these no longer reach package consumers, and editing a working Xcode project risks the example's build and signing for no published benefit.
10. Any change to the example app beyond requirement 22 and whatever Open Question 2 resolves to. The example is a user-facing surface and must not grow opportunistically.
11. Refreshing the stale `revision` in `.metadata`. See Follow-Ups.

## Open Questions

1. **Blocking for requirement 13.** The agreed screenshot set contains an overlap discovered after it was agreed. `example/lib/main.dart` applies the teal `#234840` / cream `#FDFCFA` style as its default in **both** appearances — `backgroundColor: #FDFCFA` with `tintColor: #234840` in light, `darkBackgroundColor: #234840` with `darkTintColor: #FDFCFA` in dark — so the "custom teal style" image would be visually identical to *both* the light-mode and dark-mode images, not just the light one. Consequently no image in the agreed set shows the zero-config appearance: `const KeyboardAccessoryStyle()` gives an unfilled pill with `UIColor.labelColor` icons, which is what a caller gets before styling anything and what most evaluators are judging. Substituting that for the third image needs the user's confirmation before capture, since requirement 13 otherwise preserves the set as resolved in [L7].
2. **Blocking for requirement 13.** Capturing the `doneOnly` image requires a change to the example app. `example/lib/main.dart` has a scope switcher but no layout or style switcher, so `KeyboardAccessoryLayout` cannot currently be exercised at runtime. Either the example gains a layout switcher — which would also make it demonstrate an API surface it presently ignores, and would fall under requirement 21's analyzer gate and Out of Scope 10 — or a temporary local edit is made purely to capture the image and then reverted, which leaves the example unable to show the feature and leaves Follow-Up 1 with no reproducible way to recapture. Needs a decision before capture.
3. Whether to ship as `0.1.0` or `1.0.0`. A change touches `pubspec.yaml` `version`, podspec `s.version`, the `CHANGELOG.md` heading, and the `^0.1.0` constraint in the README install snippet, and all four must stay consistent. Deferred beyond this work and already bounded by Out of Scope 8 — this work ships `0.1.0` regardless — but it must be settled before requirement 28's publish command is acted on, or that command names a stale version. [L9]
4. Whether a `.github/workflows` CI job should be added. Deferred beyond this work and already bounded by Out of Scope 7. [L10]
5. Whether pub.dev publisher verification is wanted before first publish, since the first upload binds the package to the authenticated account. Raised during the interview and not resolved. Unlike Open Questions 3 and 4, this has no `deferred` Interview Ledger record of its own; [L5] is `current` and does not cover it, so the ledger needs a record adding or this question needs re-asking.

## Follow-Ups

1. Extend the verification matrix to 3.32.5 and 3.41.9 using the locally installed FVM versions, converting the single-version claim into a support table. Whichever way Open Question 2 resolves affects how cheaply the screenshots can be recaptured for it. [L4]
2. Re-verify `isUsable` on each new Flutter stable release, since the engine-internal class name is the package's single point of failure. The procedure is manual and undocumented; consider writing it down as part of this follow-up.
3. `.metadata` records a stale `revision` of `00b0c91f06209d9e4a41f71b7a512d6eb3b9c694`. The file states it should not be hand-edited, so it is left alone here, but `flutter create --template=plugin .` would refresh it if desired.
4. Consider pinning the toolchain for this package with `.fvmrc`. There is no project pin today, so `flutter` resolves through FVM's global default; ten versions are installed locally and requirement 9's claim depends on which one runs.

## Notes

1. Verified starting state, measured rather than assumed on 2026-08-19: `flutter pub publish --dry-run` reports 0 warnings at a **61 KB** archive; `flutter test` passes 13/13; `flutter analyze` reports exactly 2 info-level `unnecessary_import` issues at the two locations in requirements 19 and 20; `public_member_api_docs` is enabled and clean.
2. The 61 KB figure supersedes an earlier 52 KB measurement, which predated `ai_specs/` existing. `spec.md` and `interview-ledger.md` now ship, at 14 KB and 7 KB. With requirements 23, 24, and 25 applied, the measured archive is **25 KB** with 0 warnings — so the screenshot budget in requirement 15 has more headroom than the original 52 KB baseline implied.
3. `git ls-remote https://github.com/ShahSomething/native_keyboard_accessory.git` exits 0 with no refs, confirming the remote exists and is empty. It succeeds only because `gh` holds a `repo`-scoped token in the keyring; `gh repo view` reports `visibility: PRIVATE`, `isEmpty: true`, `defaultBranchRef.name: ""`. See requirement 7.
4. Git identity is already correct: global `user.name` is `shahsomething` and `user.email` is `shahsomething@yahoo.com`, matching [L3], so no TenTwenty attribution enters the commit history. `init.defaultBranch` is unset — see requirement 26.
5. Running `flutter analyze` during exploration caused the tool to add platform and build exclusions to `analysis_options.yaml` automatically. That change is retained. Expect the same automatic edit to `example/analysis_options.yaml` when requirement 22's change triggers a fresh `flutter pub get` there.
6. The toolchain is FVM-managed at `/Users/tentwenty/fvm/versions/3.47.0`, selected via FVM's global default rather than a project pin. Installed versions are 3.32.5, 3.32.8, 3.35.2, 3.38.5, 3.38.9, 3.41.9, 3.44.0, 3.44.4, 3.44.5, 3.47.0. Flutter 3.27 is **not** installed, so requirement 22's floor claim cannot be verified empirically here.
7. Full toolchain identity as of exploration: Flutter 3.47.0, framework revision `4cf2416426`, engine revision `5f77625673`, Dart 3.13.0, Xcode 26.6. Requirement 9 requires these be re-captured during the verification session rather than copied from here.
8. Capture environment is available: the `iPhone 17 Pro Max` simulator (iOS 26.5) is booted.
9. Image tooling, measured: `sips -s format webp` fails with `Can't write format: org.webmproject.webp`; `cwebp` and ImageMagick are not installed; Python `PIL 11.3.0` reports `features.check('webp') == True` and successfully wrote a 1320x1290 quality-85 WebP. Dart `image 4.9.1` is also in the pub cache.
10. `example/ios/Flutter/Generated.xcconfig` and `flutter_export_environment.sh` contain a stale `FLUTTER_ROOT` of 3.41.9 and an absolute path into an unrelated project. They are already excluded from the archive by `example/ios/.gitignore`, and requirement 24 excludes the whole directory. No action needed, but the exclusion must not be disturbed.
