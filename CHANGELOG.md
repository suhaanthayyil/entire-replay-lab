# Changelog

## v0.1.55 - 2026-06-03

- Required replay file-list entries now reject empty or whitespace-only values
  in the schema contract.
- Applied non-blank string checks to `changed_files`, `files_touched`, and
  metric file buckets.
- Added validator negative checks that mutate file-list arrays to blank values
  so schema regressions fail locally.
- Updated acceptance, architecture, testing, command, and JSON schema docs.

## v0.1.54 - 2026-06-03

- Added local JSON Schema `uniqueItems` support to the dependency-free example
  validator.
- Replay file-list arrays and eval `agents` now reject duplicate entries in the
  schema contract.
- Added validator negative checks that mutate unique arrays to contain
  duplicates so schema regressions fail locally.
- Updated acceptance, architecture, testing, command, and JSON schema docs.

## v0.1.53 - 2026-06-03

- Added local JSON Schema `pattern` support to the dependency-free example
  validator.
- Required report identity strings now reject whitespace-only values as well as
  empty values.
- Added validator negative checks that mutate required identity strings to
  blank whitespace values so schema regressions fail locally.
- Updated acceptance, architecture, testing, command, and JSON schema docs.

## v0.1.52 - 2026-06-03

- Added local JSON Schema `minLength` support to the dependency-free example
  validator.
- Required report identity strings now reject empty values, including replay
  IDs, eval IDs, agents, checkpoint IDs, prompts, and commit anchors.
- Added validator negative checks that mutate required identity strings to empty
  values so schema regressions fail locally.
- Updated acceptance, architecture, testing, command, and JSON schema docs.

## v0.1.51 - 2026-06-03

- Recovered missing embedded replay run IDs inside eval reports from the eval
  report ID and original run position.
- Preserved existing embedded run IDs while filling only missing values.
- Strengthened Go coverage for eval reports with both missing top-level IDs and
  missing embedded run IDs.
- Updated acceptance, architecture, testing, JSON schema, and reproducibility
  docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.50 - 2026-06-03

- Recovered missing top-level replay report IDs from the report filename when
  reading legacy replay reports.
- Recovered missing top-level eval report IDs from the report filename when
  reading legacy eval reports.
- Strengthened Go coverage proving recovered IDs are preserved in JSON output.
- Updated acceptance, architecture, testing, JSON schema, and reproducibility
  docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.49 - 2026-06-03

- Normalized unknown non-empty replay statuses to `failed` and unknown test
  statuses to `skipped` before JSON output.
- Preserved the original unknown status strings as replay warnings so legacy
  data remains auditable.
- Recomputed eval summaries after status normalization so summary counts match
  rendered run rows.
- Strengthened Go coverage for standalone replay reports and eval reports with
  unknown legacy statuses.
- Updated acceptance, architecture, testing, JSON schema, and reproducibility
  docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.48 - 2026-06-03

- Normalized missing or empty replay `status` values to `failed` when reading
  or printing reports.
- Applied the same conservative default to replay runs embedded in eval reports,
  keeping recomputed summaries aligned with the rendered JSON.
- Strengthened Go coverage for standalone replay reports, eval reports, and
  direct JSON rendering with missing run statuses.
- Updated acceptance, architecture, testing, JSON schema, and reproducibility
  docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.47 - 2026-06-03

- Normalized missing or empty `test.status` values to `skipped` when reading or
  printing replay reports.
- Applied the same normalization to replay runs embedded in eval reports.
- Strengthened Go coverage for standalone replay reports, eval reports, and
  direct JSON rendering with sparse legacy test objects.
- Updated acceptance, architecture, testing, JSON schema, and reproducibility
  docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.46 - 2026-06-03

- Preserved requested `test.command` values on skipped test rows when replay
  setup, agent execution, checkpoint resolution, or agent availability prevents
  the command from running.
- Added a shared skipped-test initializer so synthetic replay/eval rows keep the
  same test-command evidence.
- Strengthened Go coverage for setup failure, agent failure, missing
  checkpoint, and missing-agent-command skip paths.
- Updated acceptance, architecture, testing, JSON schema, and reproducibility
  docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.45 - 2026-06-03

- Preserved selected eval `agents` when normalizing reports with empty `runs`
  arrays, so sparse legacy eval reports do not lose selection metadata.
- Kept deduplication and stable empty `summaries`/`runs` arrays for those empty
  eval reports.
- Added focused Go coverage for legacy empty-run eval reports with selected
  agents.
- Updated acceptance, architecture, testing, JSON schema, and reproducibility
  docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.44 - 2026-06-03

- Recomputed eval report summaries from embedded replay runs during save, read,
  and JSON output normalization, preventing stale summary totals from leaking
  into `entire eval report --json`.
- Derived missing or mismatched eval `agents` arrays from embedded replay runs
  while preserving valid existing agent lists.
- Added focused Go coverage for legacy eval reports with null summaries and
  stale summary totals.
- Updated acceptance, architecture, testing, JSON schema, and reproducibility
  docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.43 - 2026-06-03

- Normalized required replay/eval JSON arrays when saving, reading, or printing
  reports, so legacy `null` arrays are re-emitted as schema-valid empty arrays.
- Ensured eval `summaries` is always serialized, including the empty-array case
  required by the schema.
- Added focused Go coverage for legacy replay and eval reports with null
  `files_touched`, `changed_files`, `agents`, `summaries`, and `runs` arrays.
- Updated acceptance, architecture, testing, JSON schema, and reproducibility
  docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.42 - 2026-06-03

- Kept replay reports schema-stable when post-run diff inspection fails,
  recording a warning while preserving `changed_files` as an empty array.
- Added focused Go coverage proving saved diff-inspection failure reports avoid
  `changed_files: null`.
- Updated acceptance, architecture, testing, JSON schema, and reproducibility
  docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.41 - 2026-06-03

- Saved a failed replay report when worktree setup fails after checkpoint
  resolution, preserving the run ID, spec, agent, model, skipped test status,
  stable empty changed-file arrays, and setup error.
- Added focused Go coverage proving the replay agent is not launched after
  setup failure and that the saved JSON report remains inspectable.
- Updated acceptance, architecture, testing, and reproducibility docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.40 - 2026-06-03

- Added saved replay warnings when an installed `entire-sem` command fails,
  emits invalid JSON, or cannot complete semantic scoring.
- Missing `entire-sem` still degrades quietly as an optional feature, while
  installed-but-broken semantic scoring is now visible in reports.
- Added focused Go coverage for persisted semantic-scoring failure warnings.
- Updated acceptance, architecture, testing, FAQ, and reproducibility docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.39 - 2026-06-03

- Split replay timeout handling into independent setup, agent, and test-command
  budgets so a slow-but-successful agent does not steal the test command's
  timeout window.
- Added focused Go coverage proving `--timeout` applies separately to the agent
  replay step and the optional test command.
- Updated command, acceptance, architecture, testing, and reproducibility docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.38 - 2026-06-03

- Preserved the replay worktree path in saved reports when automatic cleanup
  fails, so leaked non-kept worktrees remain inspectable and removable.
- Added focused Go coverage for cleanup-failure report persistence.
- Updated acceptance, architecture, testing, and reproducibility docs.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.37 - 2026-06-03

- Hardened eval runs so checkpoint resolution failures still emit one
  schema-valid failed row per selected agent.
- Missing-checkpoint eval rows now preserve selected agent names, model
  overrides, stable empty arrays, skipped test status, and per-agent summaries.
- Added focused Go coverage for the missing-checkpoint eval matrix behavior.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.36 - 2026-06-03

- Added structured `test.error` output for failed replay test commands.
- Test command timeouts now preserve the deadline cause and partial test output
  in saved JSON reports and rendered text reports.
- Updated the ReplayRun schema and eval example payload to validate the new
  optional test error field.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.35 - 2026-06-03

- Hardened optional semantic scoring to build its comparison commit from a
  copied temporary git index instead of moving and resetting replay worktree
  `HEAD`.
- Semantic scoring now includes staged and untracked replay output while
  preserving the kept worktree's real HEAD and index state exactly.
- Added focused Go coverage for semantic scratch-index isolation.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.34 - 2026-06-03

- Hardened replay diff collection to use a temporary git index, so untracked
  replay output is still captured without leaving intent-to-add state in kept
  replay worktrees.
- Added Go coverage proving kept replay worktrees show untracked files
  naturally after diff collection.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.33 - 2026-06-03

- Hardened replay/eval timeout handling so explicit non-positive `--timeout`
  values fail before agent lookup or checkpoint discovery instead of disabling
  the replay timeout.
- Added Go and binary command-surface coverage for replay and eval timeout
  validation.
- Refreshed the patch artifact and pinned patch SHA-256.

## v0.1.32 - 2026-06-03

- Added `scripts/check-refresh-patch.sh` to prove patch refresh reproduces the
  checked-in patch from a dirty patched CLI checkout without mutating the
  source checkout's git status.
- Wired the patch-refresh regression into smoke, release checks, GitHub Actions
  CI, repo verification, and docs.

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
