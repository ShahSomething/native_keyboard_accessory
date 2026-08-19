---
type: Work Item
title: Verification gates, git repository and push, and publish handover
parent: ../spec.md
---

## What to build

Close the work: run every verification gate with real output, put the package
under version control and push it, and hand the publish command to the user
without running it.

1. **Verification gates.** Run all of the following and report the real output,
   not a summary:
   - `flutter analyze` at the package root — zero issues.
   - `flutter analyze` in `example/` — zero issues.
   - `flutter test` — all tests green.
   - `flutter pub publish --dry-run` — zero warnings.
   - The resulting archive size, which must not exceed **400 KB**.
   - The unpacked-archive `tentwenty` search, re-run against the final archive.
   - The character count of each `screenshots:` description.
   - The unauthenticated repository-visibility check below, reported even if it
     fails.

2. **Visibility check.** Run
   `curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/ShahSomething/native_keyboard_accessory`
   and report the status code. `git ls-remote` and `gh` are not substitutes.

3. **Version control.** `git init -b main`, commit the work as a single initial
   commit, add `https://github.com/ShahSomething/native_keyboard_accessory.git`
   as `origin`, and push with upstream tracking set.

4. **Do not publish.** `flutter pub publish` must not be executed, and pub.dev
   credentials must not be authenticated or altered.

5. **Handover.** Surface the exact publish command together with the two
   preconditions that are the user's own to satisfy: the repository must be
   public, and the version decision in Open Question 3 must be settled first.

## Required context

A size report alone is not a gate. The 27 MB archive measured in requirement 23
passed the dry-run with zero warnings, so the 400 KB ceiling has to be asserted
explicitly against the reported size.

Requirement 7 mandates an **unauthenticated** check because the authenticated
tools lie here. Spec Note 3, measured: `git ls-remote` exits 0 with no refs, but
only because `gh` holds a `repo`-scoped token in the keyring; `gh repo view`
reports `visibility: PRIVATE`, `isEmpty: true`,
`defaultBranchRef.name: ""`. A private repository returns 404 to the evaluators
this package is being published for.

The push itself succeeds against a private repository using those cached
credentials, so requirement 7 gates the **handover**, not the push. Push
regardless of visibility; withhold the ready-to-run framing of the publish
command until the check returns `200`.

Requirement 26: the branch name must be `main` explicitly. `init.defaultBranch`
is unset locally so `git init` would otherwise produce `master`, the remote has no
default branch yet so the first pushed branch becomes the default, and pub.dev
resolves the README's relative image paths against `repository` plus that default
branch. The remote is empty, so this is a first push with no overwrite risk.

Spec Note 4: git identity is already correct — global `user.name` is
`shahsomething` and `user.email` is `shahsomething@yahoo.com`, matching L3, so no
TenTwenty attribution enters the commit history.

`ai_specs/` is excluded from the archive by `04-archive-exclusion.md` but must be
committed and pushed, so the initial commit includes
`ai_specs/0001-pub-dev-readiness/spec.md`,
`ai_specs/0001-pub-dev-readiness/interview-ledger.md`, and this
`work-items/` directory.

Technical Decision 5: publishing is excluded because it is irreversible in three
distinct ways — the package name is claimed permanently, version `0.1.0` can never
be re-uploaded, and the upload binds the package to whichever pub.dev account is
authenticated, an identity that just changed hands in L1 and L2.

Open Question 5 — whether pub.dev publisher verification is wanted before first
publish — is unresolved and has no Interview Ledger record of its own. It sits
outside this work's requirements. Report it as outstanding; do not act on it.

Testing Strategy 8: no automated test may depend on network access, a real device,
or credentials. The two exceptions are explicit, manual, and reported — the
simulator verification in `03-verification-and-screenshot-gallery.md` and the
unauthenticated visibility check here.

## Acceptance criteria

- [ ] `flutter analyze` at the package root reports zero issues, with real output included in the report.
- [ ] `flutter analyze` run from inside `example/` reports zero issues, with real output included in the report.
- [ ] `flutter test` passes all tests, with real output included in the report.
- [ ] `flutter pub publish --dry-run` reports zero warnings, with real output included in the report.
- [ ] The archive size the dry-run reports is stated explicitly and asserted not to exceed 400 KB.
- [ ] The unpacked-archive search for `TenTwenty`, `tentwenty`, and `dev@tentwenty.me` is re-run against the final archive and reported as finding nothing.
- [ ] The character count of each `screenshots:` description is reported per entry, and every count is between 10 and 160.
- [ ] `curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/ShahSomething/native_keyboard_accessory` is run unauthenticated and its status code is reported, including when it is not `200`.
- [ ] Neither `git ls-remote` nor `gh` is used as a substitute for that visibility check.
- [ ] `git init -b main` is used, so the branch is `main` explicitly rather than whatever unset `init.defaultBranch` would produce.
- [ ] The work is committed as a single initial commit.
- [ ] That commit includes `ai_specs/0001-pub-dev-readiness/spec.md`, `ai_specs/0001-pub-dev-readiness/interview-ledger.md`, and the `work-items/` directory.
- [ ] `https://github.com/ShahSomething/native_keyboard_accessory.git` is configured as `origin`.
- [ ] `main` is pushed with upstream tracking set.
- [ ] `flutter pub publish` is not executed at any point.
- [ ] pub.dev credentials are neither authenticated nor altered.
- [ ] The exact publish command is surfaced to the user on completion.
- [ ] It is surfaced together with both user-owned preconditions: that the repository must be public, and that the `0.1.0` versus `1.0.0` decision must be settled first because choosing `1.0.0` changes `pubspec.yaml` `version`, podspec `s.version`, the `CHANGELOG.md` heading, and the `^0.1.0` constraint in the README install snippet.
- [ ] While the unauthenticated check returns anything other than `200`, the publish command is presented as gated behind the visibility flip rather than as ready to run.
- [ ] Open Question 5 is reported as outstanding without being acted on.

## Covers

- User Stories: 1, 5
- Requirements: 7, 26-29
- Testing Strategy: 6, 8
- Interview Ledger: L5, L9
- Technical Decisions: 5

## Blocking decisions

- **Requirement 7 — repository visibility.** Flipping
  `github.com/ShahSomething/native_keyboard_accessory` to public is the user's
  action, not this work's. The check must be reported either way, and the publish
  handover stays blocked until it returns `200`. The push is not blocked by this.
- **Open Question 3 — version.** This work ships `0.1.0` regardless, bounded by
  Out of Scope 8, so execution is not blocked. But the surfaced publish command
  names a version, so the user must settle `0.1.0` versus `1.0.0` before acting
  on it, or the command is stale.

## Blocked by

- `01-ownership-and-license-metadata.md`
- `02-analyzer-hygiene-and-example-floor.md`
- `03-verification-and-screenshot-gallery.md`
- `04-archive-exclusion.md`
