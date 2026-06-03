# Changelog

## v0.1.7 - 2026-06-03

- Expanded command-surface verification to require public replay/eval flags.

## v0.1.6 - 2026-06-02

- Added a shared Replay/Eval command-surface verifier and CI gate.

## v0.1.5 - 2026-06-02

- Added patch manifest validation to catch accidental broad upstream patch changes.

## v0.1.4 - 2026-06-02

- Added post-release verification for release notes, local tags, and GitHub releases.

## v0.1.3 - 2026-06-02

- Added automatic validation that changelog versions match release-note files.
- Removed hardcoded release-note version checks from repository verification.

## v0.1.2 - 2026-06-02

- Centralized pinned Entire CLI repo/ref/patch defaults in `scripts/replay-lab-env.sh`.
- Added reproducibility verification for pinned build inputs and docs.
- Made patch refresh default to the same pinned base as build and patch checks.

## v0.1.1 - 2026-06-02

- Added local Markdown link validation to catch broken docs references in CI.

## v0.1.0 - 2026-06-02

- Added a self-contained Replay Lab patch against a known Entire CLI base.
- Added build, verify, patch-check, patch-refresh, demo, and clean scripts.
- Added architecture, testing, JSON schema, demo, roadmap, and CEO-message docs.
- Added CI for repo validation, patched CLI build, and Replay Lab patch tests.
- Added a doctor script and FAQ for local setup validation.
- Added a smoke script plus acceptance and product-brief docs.
- Added dependency-free JSON example validation against local schemas.
- Updated CI to Node 24-based GitHub Actions and disabled unused Go caching.
- Added README badges, GitHub templates, Dependabot, and command reference docs.
- Added release-check tooling and v0.1.0 prototype release notes.
