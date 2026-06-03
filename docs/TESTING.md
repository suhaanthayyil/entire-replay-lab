# Testing

Replay Lab has three levels of validation.

## Repo Validation

Run this before committing docs, schemas, or scripts:

```bash
./scripts/verify-repo.sh
```

It checks:

- JSON examples parse successfully.
- JSON value kinds reject wrong types at root and nested object levels through
  local `type` schema checks.
- JSON examples validate against the local schemas, including rejection of
  undocumented additional fields where root or nested schemas are closed.
- Schema versions and replay/test statuses reject values outside their local
  `const` and `enum` contracts.
- Required replay/eval fields reject missing keys at root and nested object
  levels through local `required` schema checks.
- Required replay/eval identity strings reject empty or whitespace-only values
  through local `minLength` and `pattern` schema checks.
- Set-like replay/eval arrays reject duplicate values through local
  `uniqueItems` schema checks.
- Replay file-list arrays reject empty or whitespace-only entries.
- Numeric replay/eval fields reject negative values or values above their
  declared maximums through local `minimum` and `maximum` schema checks.
- Replay/eval timestamps reject malformed values through local `date-time`
  format checks.
- Replay/eval timestamp consistency rejects reports that finish before they
  start.
- Eval examples validate each embedded replay run against the ReplayRun schema.
- Eval summaries are checked against their embedded replay runs, including
  status counts, pass rate, averages, risk, duration, and token totals.
- Schemas parse successfully.
- Project metadata, README badges, and MIT license text stay consistent.
- Main docs exist and include the important setup sections.
- Local Markdown links and anchors resolve.
- Markdown code fences are closed, use expected languages, and JSON snippets
  parse.
- Reusable docs and scripts avoid machine-specific local paths.
- Helper scripts keep expected shebangs, executable bits, shell safety flags,
  Python entrypoints, and command-reference sections.
- Changelog and release-note files stay in sync.
- Reproducibility metadata is in sync.
- The Replay Lab patch touches only the expected upstream files.
- Shell scripts pass `bash -n`.

## Build Validation

Build the Replay Lab-enabled Entire CLI:

```bash
./scripts/build-cli.sh
```

By default this clones `entireio/cli`, checks out the tested base commit from
`scripts/replay-lab-env.sh`, applies the included Replay Lab patch, and builds
`bin/entire`.

```text
https://github.com/entireio/cli.git@e858fb537e70b8008a10f712cb73588cb67aacf2
patches/entire-replay-lab.patch
```

To verify those pinned inputs:

```bash
./scripts/verify-reproducibility.sh
```

To verify the patch file surface:

```bash
./scripts/verify-patch-manifest.sh
```

To verify patch regeneration from the normal dirty patched checkout:

```bash
./scripts/check-refresh-patch.sh
```

This proves `refresh-patch.sh` reproduces the checked-in patch and does not
mutate the source checkout's git status while including untracked Replay Lab
files.

To verify the built command surface:

```bash
./scripts/build-cli.sh
./scripts/check-command-surface.sh
```

This checks the replay/eval command tree plus the required public flags used by
the README, demo, smoke, and release docs. It also verifies invalid replay
agent selections fail with clear messages, and that non-positive
`--from-checkpoints --limit` and `--timeout` values fail before checkpoint
discovery or agent launch. Timed-out test commands preserve partial test output
and a structured timeout error in saved reports. Replay agents and optional test
commands each receive a fresh `--timeout` budget.

To verify saved report rendering:

```bash
./scripts/build-cli.sh
./scripts/check-report-fixtures.sh
```

This seeds the example result JSON into a temporary git repo and runs
`entire replay report` plus `entire eval report` in text and `--json` modes.
The generated `--json` output is validated against the local schemas.
The eval report fixture also proves embedded replay runs stay schema-valid.
It also checks that missing replay/eval report IDs fail clearly in both normal
and `--json` modes instead of rendering empty or misleading output.
Missing checkpoint IDs in eval runs are represented as one failed replay row
per selected agent, so saved reports still have complete per-agent summaries
and stable empty arrays.

To verify `--agent all` at the command level without live model calls:

```bash
./scripts/build-cli.sh
./scripts/check-all-agent-eval.sh
```

This creates a temporary repo with a committed Entire checkpoint, runs
`entire eval run --agent all --json`, validates the generated eval JSON, and
confirms the rendered report lists every built-in Entire coder. It also checks
that an explicit unknown eval agent renders as a schema-valid skipped run.

After publishing a release, verify release docs, local tags, and GitHub releases:

```bash
./scripts/verify-release-state.sh
```

To use a local CLI checkout that already has Replay Lab applied:

```bash
ENTIRE_CLI_SOURCE=/path/to/cli-replay-lab ./scripts/build-cli.sh
```

To use a different fork or branch:

```bash
ENTIRE_CLI_REPO=https://github.com/<user>/cli.git \
ENTIRE_CLI_REF=<branch> \
ENTIRE_REPLAY_PATCH=/path/to/replay.patch \
./scripts/build-cli.sh
```

## Patch Validation

Run the patch against a fresh temp clone and execute the Replay Lab test slice:

```bash
./scripts/check-patch.sh
```

Refresh the patch from a local CLI checkout after changing the implementation:

```bash
ENTIRE_CLI_SOURCE=/path/to/cli-replay-lab ./scripts/refresh-patch.sh
```

The refresh helper diffs the current local checkout against the pinned upstream
base and includes new Replay Lab files without mutating the checkout's real git
index.

Remove generated binaries and temp clones:

```bash
./scripts/clean.sh
```

## Smoke Validation

Run the main local proof path:

```bash
./scripts/smoke.sh /path/to/entire-enabled/repo
```

This runs repo verification, patched CLI build, patch-refresh regression,
build-lock concurrency, command-surface checks, report fixtures, all-agent eval
fixtures, doctor, and fresh-clone patch tests.

## Live Validation

Use a repo that already has Entire checkpoints:

```bash
cd /path/to/entire-enabled/repo
entire checkpoint list
```

Before running an agent replay, check local prerequisites:

```bash
./scripts/doctor.sh /path/to/entire-enabled/repo
```

Replay one checkpoint:

```bash
/path/to/entire-replay-lab/bin/entire replay checkpoint <checkpoint-id> \
  --agent claude-code \
  --test-cmd "python3 -m pytest" \
  --keep-worktree
```

Run a small eval:

```bash
/path/to/entire-replay-lab/bin/entire eval run \
  --from-checkpoints \
  --limit 3 \
  --agent all \
  --test-cmd "python3 -m pytest"
```

## What Good Looks Like

- The current worktree stays clean.
- Replay creates a temp worktree at the checkpoint base.
- Output includes status, range, file metrics, tests, optional semantic score,
  risk, and saved report path.
- Saved JSON lands under `.git/entire-replay/`.
- Saved JSON uses non-blank required identity strings for report IDs, agents,
  checkpoint IDs, prompts, and commit anchors.
- Saved JSON keeps selected agents and file-list evidence deduplicated where
  the schema treats those arrays as sets.
- Saved JSON does not use blank strings as file-list evidence.
- Saved JSON timestamps are valid RFC3339 date-time strings.
- Saved JSON never reports `finished_at` earlier than `started_at`.
- Skipped test rows still preserve the requested test command when earlier
  replay failures prevent execution.
- Legacy reports with sparse run objects still render with replay `status` set
  to `failed`.
- Legacy reports with unknown run or test statuses still render schema-valid
  statuses and preserve the original values in warnings.
- Legacy reports with sparse test objects still render with `test.status` set
  to `skipped`.
- Legacy reports with missing top-level IDs still render with IDs recovered from
  their report filenames.
- Legacy eval reports with missing embedded run IDs still render with stable
  IDs derived from the eval ID and original run position.
- Worktree setup failures after checkpoint resolution still save a failed report
  with a skipped test status and stable empty changed-file array.
- Diff-inspection failures still save a report warning and stable empty
  `changed_files` array.
- Legacy reports with null required arrays are normalized to schema-valid empty
  arrays when read or printed as JSON.
- Legacy eval reports with missing or stale summaries are repaired from embedded
  replay runs before JSON output.
- Sparse legacy eval reports with selected agents and empty runs preserve the
  selected agent list.
- `--timeout` applies independently to the replay agent and optional test
  command rather than using one shared wall-clock budget.
- `--keep-worktree` prints a path you can inspect without Replay Lab leaving
  intent-to-add index state behind.
- Cleanup failures still save the surviving replay worktree path with the
  warning, so operators can inspect or remove the leaked worktree.
- Optional semantic scoring preserves kept replay worktree `HEAD` and index
  state while still seeing staged and untracked replay output.
- Missing agents and missing `entire-sem` degrade clearly without corrupting the
  repo; installed-but-failing `entire-sem` emits a saved warning.
- `--agent all` covers every built-in Entire coder, with Pi shown as skipped
  until a safe non-interactive launch contract exists.
