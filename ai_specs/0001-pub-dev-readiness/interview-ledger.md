---
type: Interview Ledger
parent: spec.md
---

## Records

### L1

Status: current

Question: The package declares `github.com/tentwenty/native_keyboard_accessory` as `repository`, `issue_tracker`, and podspec `homepage`, but the stated push target is `github.com/ShahSomething/native_keyboard_accessory`. Which is canonical?

Answer: ShahSomething is the owner, not TenTwenty.

Decision: `github.com/ShahSomething/native_keyboard_accessory` is the canonical repository URL for `pubspec.yaml` `repository`, `pubspec.yaml` `issue_tracker`, and the podspec `homepage`.

Reason: pub.dev renders `repository` as a live link and uses it for repository verification. Pointing it at `tentwenty/` while the code lives at `ShahSomething/` ships a broken link, or a 404 if the TenTwenty repo is private.

### L2

Status: current

Question: Should the license stay MIT, and who is the copyright holder?

Answer: Use the MIT open source license, with ShahSomething as owner rather than TenTwenty.

Decision: License remains MIT. The `LICENSE` copyright line becomes `Copyright (c) 2026 ShahSomething`.

Reason: An MIT copyright line naming a holder who does not own the work is a defective license grant, not a cosmetic mismatch. Hosting location and copyright ownership were confirmed to be the same party here.

Negative Requirements:
- Do not change the license type away from MIT.
- Do not retain `TenTwenty` as copyright holder.

### L3

Status: current

Question: What exact identity strings should go in the license and package metadata, including the author email, and should `homepage`/`funding` be added?

Recommended Answer:
- Podspec `author` as a name plus email pair.
- Leave `homepage` and `funding` unset, because `repository` already gives pub.dev the repo link.

Answer: email: shahsomething@yahoo.com

Decision: Podspec `author` becomes `{ 'ShahSomething' => 'shahsomething@yahoo.com' }`. `pubspec.yaml` gains no `homepage` and no `funding` field.

Reason: The previous `dev@tentwenty.me` address is replaced rather than kept alongside, so no TenTwenty reference survives in the published artifact.

### L4

Status: current

Question: How far should the engine patch actually be verified across Flutter versions, and how should the README state compatibility?

Recommended Answer:
- Option A: verify three versions (3.32.5, 3.41.9, 3.47.0) and publish a support matrix.
- Option B: verify 3.47.0 only and rewrite the claim as "verified on 3.47.0; earlier versions rely on the `isUsable` canary".

Answer: verify 3.47.0 only

Decision: Verify empirically on Flutter 3.47.0 only. Replace the stale `README.md:171` claim with a statement naming 3.47.0 and its engine revision, and stating that versions below it down to the declared floor are permitted but unverified, with `isUsable` as the runtime canary. The declared floor stays `sdk: ^3.6.0` / `flutter: '>=3.27.0'`.

Reason: The floor is deliberate, not accidental: `Color.toARGB32()` in `lib/src/keyboard_accessory_style.dart` is the API that replaced deprecated `Color.value` in Flutter 3.27. The patch fails closed via `NSClassFromString`, so an unverified older version degrades to "no bar" rather than crashing, which makes the wide floor an honest trade once the README says so.

Negative Requirements:
- Do not update the version number in the README claim without running the verification.
- Do not claim verification for any version not actually exercised.

Answer History:
- Recommended: verify 3.32.5, 3.41.9 and 3.47.0 and ship a matrix, since FVM has all three installed locally.
- Final answer: verify 3.47.0 only, accepting the cheaper canary-based wording for earlier versions.

### L5

Status: current

Question: Should the task end at "prepared and pushed to GitHub", or continue through to publishing on pub.dev?

Recommended Answer:
- Take the package to publish-ready, commit, and push to the empty GitHub repo.
- Stop before `flutter pub publish` and hand over the exact command.

Answer: Recommendation carried unopposed; no instruction to publish was given.

Decision: Do not run `flutter pub publish` in this work. Finish at a pushed, publish-ready repository and surface the publish command for the user to run.

Reason: The push is fully reversible; publishing is not. The package name is claimed permanently on first upload and version `0.1.0` can never be replaced, only retracted. Publishing also binds the package to whichever pub.dev account is authenticated, which is an identity decision that just changed owner in L1 and L2.

Negative Requirements:
- Do not execute `flutter pub publish`.
- Do not authenticate or alter pub.dev credentials.

### L6

Status: current

Question: Should the package ship screenshots for the pub.dev gallery and README?

Answer: Include images as well.

Decision: The package ships screenshot images, wired into both the pub.dev `screenshots:` gallery and the README.

Reason: The package's value proposition is visual — a bar above the keyboard — so a package page with no image is a substantive gap rather than a polish item.

### L7

Status: current

Question: Which screenshots, framed how, and in what format, given that pub.dev `screenshots:` files must ship inside the published archive?

Recommended Answer:
- Four images: numeric keypad with bar in light mode; the same in dark mode; the README's custom teal `#234840` / cream `#FDFCFA` style; and the `doneOnly` layout.
- Cropped to roughly the bottom 45%, bar plus keyboard, so the bar is the subject rather than a thin sliver.
- WebP at approximately quality 85, around 40-80 KB each, keeping the archive near 300 KB instead of 3 MB.
- Stored in `doc/images/`, single-sourced so pubspec `screenshots:` and the inline README reference the same files by relative path.
- Each pubspec entry needs a `description` of 10-160 characters.

Answer: Do the recommended

Decision: Produce exactly those four cropped WebP images in `doc/images/`, referenced by both `pubspec.yaml` `screenshots:` and the README via relative paths.

Reason: Raw iPhone 17 Pro Max simulator PNGs are 1320x2868 at 3x and 500 KB-1 MB each. Four full-frame PNGs would grow the 52 KB archive roughly 60x while rendering the accessory bar as about 6% of the image height in a small gallery strip.

Examples:
- pub.dev rewrites relative README links against `repository`, and GitHub renders them natively, so one file set serves both surfaces with no `raw.githubusercontent` URLs to rot.

### L8

Status: current

Question: Where should ACT workflow artifacts be stored for this package, and which agent guidance file should be created?

Recommended Answer:
- Local markdown backend, because the directory is not a git repository yet so no GitHub remote exists to host Issues.
- `ai_specs` as the local path.
- `AGENTS.md` as the cross-tool guidance file.

Answer: Local markdown, `ai_specs`, `AGENTS.md`

Decision: `.act/config.yaml` uses `workflow.backend: local` with `local.path: ai_specs`. Agent guidance lives in `AGENTS.md`.

Reason: Workflow artifacts created inside the package directory would otherwise be swept into the published pub.dev archive, so the storage choice creates an explicit ignore requirement.

### L9

Status: deferred

Question: Should the package ship as `0.1.0` or move to `1.0.0` for its first publish?

Answer: Not resolved during the interview.

Decision: Deferred. Version stays `0.1.0` unless the user decides otherwise before publishing.

Reason: A version change touches `pubspec.yaml` `version`, podspec `s.version`, the `CHANGELOG.md` heading, and the `^0.1.0` constraint in the README install snippet, so it must stay consistent across all four.

### L10

Status: deferred

Question: Should a `.github/workflows` CI job be added?

Answer: Not resolved during the interview.

Decision: Deferred. No CI workflow is added by this work.

Reason: Raised as a non-blocking quality item at the Spec-ready checkpoint and not selected.

### L11

Status: current

Question: Is `github.com/ShahSomething/native_keyboard_accessory` public, as requirement 7 requires before the publish command is handed over as ready to run?

Answer: The user flipped the repository to public on 2026-08-20.

Decision: Requirement 7 is satisfied. The unauthenticated check `curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/ShahSomething/native_keyboard_accessory` returns `200`, the API reports `visibility: public` and `default_branch: main`, and all four `doc/images/*.webp` paths return `200` from `raw.githubusercontent.com` on `main`. The publish handover is no longer gated on visibility.

Reason: A private repository returns 404 to unauthenticated readers, which breaks the `repository` link pub.dev renders and the relative README image paths pub.dev resolves against `repository` plus the default branch. Verified unauthenticated because the cached `gh` token makes the authenticated tools report success either way.

### L12

Status: current

Question: Should the package ship as `0.1.0` or move to `1.0.0` for its first publish? (Resolves the deferral in L9.)

Answer: Ship `0.1.0`.

Decision: The first published version is `0.1.0`. No version edits are made: `pubspec.yaml` `version`, podspec `s.version`, the `CHANGELOG.md` heading, and the `^0.1.0` constraint in the README install snippet are already consistent at `0.1.0` and stay as they are.

Reason: A pre-1.0 version signals an unstable API, leaving room for breaking changes in `0.2.0` without violating a major-version promise on a package whose first release has no field usage yet.

### L13

Status: deferred

Question: Should pub.dev publisher verification be set up before the first publish, since the first upload permanently binds the package to whichever account is authenticated? (Adds the missing record for Open Question 5.)

Answer: Leave it outstanding. The user chose to publish under their individual pub.dev account.

Decision: Deferred. No publisher verification is set up by this work, and no pub.dev credentials are authenticated or altered. A verified publisher may be added later.

Reason: Open Question 5 was raised during the interview and had no ledger record of its own; L5 is `current` and does not cover it. This record closes that gap. Adding a verified publisher after the fact is a manual pub.dev administration step, which the user accepted.

### L14

Status: current

Question: Which pub.dev account should the first upload permanently bind the package to?

Answer: `shah.raza52@gmail.com`, confirmed by the user on 2026-08-20.

Decision: The package is published under `shah.raza52@gmail.com`. Verified locally by decoding the `idToken` claim in `pub-credentials.json`: `email_verified: true`, and not a `@tentwenty.me` address. Credentials were read only, never authenticated or altered.

Reason: The first upload binds the package to the authenticated account permanently, and L1 and L2 moved ownership from TenTwenty to the individual. The account is a third address, distinct from both the git identity `shahsomething@yahoo.com` and TenTwenty, so it was confirmed explicitly rather than assumed. With publisher verification deferred in L13, this account is the sole owner of record.
