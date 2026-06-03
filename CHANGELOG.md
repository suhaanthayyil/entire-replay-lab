# Changelog

## v0.1.31 - 2026-06-03

- Hardened `entire eval run --from-checkpoints --limit` so non-positive limits
  fail before checkpoint discovery instead of expanding to every checkpoint.
- Added binary-level command-surface coverage for the new limit validation.
- Fixed `scripts/refresh-patch.sh` so patch regeneration includes new Replay
  Lab files from a dirty local CLI checkout without mutating its real git index.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.30 - 2026-06-03

- Hardened the saved-report fixture so missing replay and eval report IDs must
  fail clearly in both text and `--json` modes.
- Documented the missing-report negative-path guarantee in acceptance, testing,
  and command-reference docs.

## v0.1.29 - 2026-06-03

- Hardened command-surface validation so `entire replay checkpoint --agent all`
  and unknown replay agents must fail with clear user-facing errors.
- Extended the all-agent eval fixture to prove an explicit unknown eval agent
  becomes a schema-valid skipped JSON run with stable empty arrays.

## v0.1.28 - 2026-06-03

- Fixed the `entire replay checkpoint` command docs so the `--agent` flag lists
  the full launchable Replay Lab runner set.
- Added a script-hygiene guard that fails if the command reference drifts back
  to an incomplete launchable agent list.

## v0.1.27 - 2026-06-03

- Added native replay runners for Copilot CLI, Cursor Agent CLI, Factory AI
  Droid, and OpenCode using their documented non-interactive CLI modes.
- Expanded the launchable `--agent all` prefix to every currently launchable
  Entire coder: Claude Code, Codex, Copilot CLI, Cursor, Factory AI Droid,
  Gemini, and OpenCode.
- Kept Pi represented in `--agent all` as a skipped eval row until Pi exposes a
  safe non-interactive launch contract.
- Updated all-agent fixtures, doctor checks, docs, examples, the patch artifact,
  and the pinned patch hash.

## v0.1.26 - 2026-06-03

- Extended `scripts/check-build-lock.sh` to verify stale lock cleanup and
  active-lock timeout behavior.
- Updated command docs and repo verification to require the stronger lock
  fixture.

## v0.1.25 - 2026-06-03

- Added `scripts/check-build-lock.sh` to prove concurrent `build-cli.sh`
  invocations serialize through the repo-local lock.
- Wired the build-lock fixture into CI, release checks, smoke checks, command
  docs, acceptance docs, testing docs, and repo verification.
- Verified the resulting binary still exposes Replay/Eval commands after
  concurrent builds finish.

## v0.1.24 - 2026-06-03

- Made `--agent all` derive from Entire's user-facing built-in coder registry
  at runtime instead of a separate hardcoded Replay Lab list.
- Kept launchable replay agents first in eval output, then sorted the remaining
  registered coders.
- Added tests for registry-derived expansion, launchable-first ordering, and
  test-only agent exclusion.
- Added a build lock so concurrent smoke, release, and manual build runs cannot
  mutate the shared patched CLI checkout at the same time.
- Refreshed the all-agent fixture, command docs, doctor output, patch artifact,
  and pinned patch hash.

## v0.1.23 - 2026-06-03

- Made `--agent all` match Entire's current user-facing built-in coder
  registry.
- Removed the internal test-only coder from normal eval expansion and docs.
- Added a regression test that fails if Replay Lab's all-agent list drifts from
  Entire's registered coder list.
- Refreshed the Replay Lab patch and pinned patch hash.

## v0.1.22 - 2026-06-03

- Added the all-agent eval fixture to GitHub Actions CI.
- Made repo verification assert that CI keeps the all-agent eval gate.
- Updated the pull request template to call out the fixture for eval or agent
  behavior changes.

## v0.1.21 - 2026-06-03

- Added a binary-level all-agent eval fixture that runs
  `entire eval run --agent all --json` against a real temporary Entire
  checkpoint.
- Fixed schema stability for synthetic skipped/failed eval runs by emitting
  empty arrays instead of `null` for replay file lists.
- Wired the all-agent fixture into smoke, release checks, command docs, and repo
  verification.

## v0.1.20 - 2026-06-03

- Added `--agent all` for eval runs across every built-in Entire coder.
- Canonicalized common agent aliases such as `gemini-cli`, `cursor-cli`, and
  `copilot`.
- Reported non-launchable Entire coder integrations as explicit skipped eval
  runs instead of hiding them.
- Validated eval summaries against embedded replay run totals.
- Kept explicit eval report checks compatible with empty run arrays.

## v0.1.19 - 2026-06-03

- Validated embedded eval replay runs through the ReplayRun schema.
- Added local cross-schema `$ref` support to the example/schema validator.

## v0.1.18 - 2026-06-03

- Validated rendered Replay/Eval report JSON against local schemas.
- Aligned `token_usage` schemas and examples with Entire agent token fields.

## v0.1.17 - 2026-06-03

- Enforced closed JSON schema objects for checked Replay/Eval examples.

## v0.1.16 - 2026-06-03

- Added helper script hygiene and command-reference coverage validation.

## v0.1.15 - 2026-06-03

- Added portability validation for reusable docs and scripts.
- Removed personal local paths from demo, testing, and patch-refresh helpers.

## v0.1.14 - 2026-06-03

- Added project metadata and MIT license hygiene validation.

## v0.1.13 - 2026-06-03

- Added Markdown fenced code block validation.

## v0.1.12 - 2026-06-03

- Extended release body verification to every published release.

## v0.1.11 - 2026-06-03

- Added latest GitHub release body verification against checked-in release notes.

## v0.1.10 - 2026-06-03

- Added latest release tag commit verification.
- Fixed release-note validation for multi-digit semver patches.
- Made command-surface help checks robust under `pipefail`.

## v0.1.9 - 2026-06-03

- Added enforced SHA-256 verification for the Replay Lab patch artifact.

## v0.1.8 - 2026-06-03

- Added binary-level Replay/Eval report fixture verification.

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
