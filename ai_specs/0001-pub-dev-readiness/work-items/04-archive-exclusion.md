---
type: Work Item
title: Archive exclusion via .pubignore
parent: ../spec.md
---

## What to build

A root `.pubignore` that keeps internal workflow artifacts, agent guidance, and
the regenerable example Xcode project out of the published archive while leaving
every one of them tracked in git.

Because `.pubignore` **replaces** `.gitignore` for `pub publish` rather than
adding to it, the file must be written as a superset: every publish-relevant
`.gitignore` entry plus the new exclusions.

Entries the file must carry:

- Inherited from `.gitignore`: `build/`, `.dart_tool/`,
  `.flutter-plugins-dependencies`, `coverage/`, `**/doc/api/`, `pubspec.lock`,
  `*.iml`, `*.ipr`, `*.iws`, `.idea/`, `.DS_Store`.
- New: `example/ios/`, `AGENTS.md`, `CLAUDE.md`, `ai_specs/`, `.act/`.

`ai_specs/` must stay out of `.gitignore` so the Spec, Interview Ledger, and
these Work Items are committed and pushed.

Then verify requirement 8 against the archive: unpack what
`flutter pub publish --dry-run` builds and search the unpacked tree for
`TenTwenty`, `tentwenty`, and `dev@tentwenty.me`.

## Required context

Zero warnings is not evidence of a correct archive. Measured in requirement 23: a
`.pubignore` listing only the new exclusions produced a **27 MB** archive with
**0 warnings**, because `build/` and `example/build/` stopped being ignored the
moment the file existed. That is the failure mode this superset prevents.

`pub publish` honours `.gitignore` even with no git repository present, which is
why the current 61 KB archive is already `.gitignore`-filtered (Technical
Decision 7).

Requirement 24: `example/ios/` is the sole remaining source of `tentwenty`
strings in the archive — `example/ios/Runner.xcodeproj/project.pbxproj` contains
`PRODUCT_BUNDLE_IDENTIFIER = com.tentwenty.nativeKeyboardAccessoryExample` at six
sites and `DEVELOPMENT_TEAM = PTEE8T35KX` at three. Excluding the directory is
what makes requirement 8 satisfiable. Editing those values is Out of Scope 9.

`example/lib/main.dart`, `example/pubspec.yaml`, `example/README.md`, and
`example/analysis_options.yaml` must continue to ship so pub.dev's example tab
still works.

Requirement 25: ACT created `CLAUDE.md` as a symlink to `AGENTS.md`, and both
currently ship with the symlink resolving to a duplicate file. Both must leave
the archive and both must remain in git — agent guidance serves contributors, not
package consumers, and `CLAUDE.md` must keep working as the Claude Code entry
point.

Spec Note 10: `example/ios/Flutter/Generated.xcconfig` and
`flutter_export_environment.sh` carry a stale `FLUTTER_ROOT` pointing at 3.41.9
and an absolute path into an unrelated project. They are already excluded by
`example/ios/.gitignore` and now by the whole-directory exclusion. No action is
needed, but the exclusion must not be disturbed.

`.gitignore` currently anchors some entries with a leading slash — `/pubspec.lock`,
`/build/`, `/coverage/`. Requirement 23 names the unanchored forms; use the forms
requirement 23 lists.

Do not exclude `doc/images/`. Those files are served from the archive for the
`screenshots:` gallery and must ship.

Testing Strategy 6: archive composition is verified by unpacking what the dry-run
builds, not by inspecting the working directory. Requirements 8, 23, 24, and 25
all describe archive contents that differ from the working tree.

## Acceptance criteria

- [x] A `.pubignore` exists at the package root.
- [x] It carries every publish-relevant `.gitignore` entry: `build/`, `.dart_tool/`, `.flutter-plugins-dependencies`, `coverage/`, `**/doc/api/`, `pubspec.lock`, `*.iml`, `*.ipr`, `*.iws`, `.idea/`, `.DS_Store`.
- [x] It also excludes `example/ios/`, `AGENTS.md`, `CLAUDE.md`, `ai_specs/`, and `.act/`.
- [x] `ai_specs/` is not added to `.gitignore`.
- [x] Nothing is deleted or untracked: `example/ios/`, `AGENTS.md`, `CLAUDE.md`, `ai_specs/`, and `.act/` all remain present in the working tree, and `CLAUDE.md` still resolves as a symlink to `AGENTS.md`.
- [x] The archive `flutter pub publish --dry-run` produces is unpacked, and the verification below is run against the unpacked tree rather than the working directory.
- [x] The unpacked archive contains no `example/ios/` directory, no `AGENTS.md`, no `CLAUDE.md`, no `ai_specs/`, and no `.act/`.
- [x] The unpacked archive still contains `example/lib/main.dart`, `example/pubspec.yaml`, `example/README.md`, and `example/analysis_options.yaml`.
- [x] The unpacked archive contains no `build/` or `example/build/` directory.
- [x] The unpacked archive still contains `doc/images/` and its four WebP files, once `03-verification-and-screenshot-gallery.md` has produced them.
- [x] Searching the unpacked archive finds no occurrence of `TenTwenty`, `tentwenty`, or `dev@tentwenty.me`.
- [x] `flutter pub publish --dry-run` reports zero warnings, and the measured archive size is reported and is in the tens of kilobytes plus screenshots — not the 27 MB a delta-only `.pubignore` produced.

## Covers

- User Stories: 6
- Requirements: 8, 23-25
- Testing Strategy: 6
- Interview Ledger: L1, L3, L8
- Technical Decisions: 6, 7

## Blocked by

- `01-ownership-and-license-metadata.md` — requirement 8's archive search only
  becomes satisfiable once the metadata edits have removed the TenTwenty strings
  that this Work Item's `example/ios/` exclusion does not cover.
