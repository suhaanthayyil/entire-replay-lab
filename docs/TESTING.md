# Testing

Replay Lab has three levels of validation.

## Repo Validation

Run this before committing docs, schemas, or scripts:

```bash
./scripts/verify-repo.sh
```

It checks:

- JSON examples parse successfully.
- JSON examples validate against the local schemas, including rejection of
  undocumented additional fields where the schema is closed.
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

To verify the built command surface:

```bash
./scripts/build-cli.sh
./scripts/check-command-surface.sh
```

This checks the replay/eval command tree plus the required public flags used by
the README, demo, smoke, and release docs. It also verifies invalid replay
agent selections fail with clear messages.

To verify saved report rendering:

```bash
./scripts/build-cli.sh
./scripts/check-report-fixtures.sh
```

This seeds the example result JSON into a temporary git repo and runs
`entire replay report` plus `entire eval report` in text and `--json` modes.
The generated `--json` output is validated against the local schemas.
The eval report fixture also proves embedded replay runs stay schema-valid.

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

Remove generated binaries and temp clones:

```bash
./scripts/clean.sh
```

## Smoke Validation

Run the main local proof path:

```bash
./scripts/smoke.sh /path/to/entire-enabled/repo
```

This runs repo verification, patched CLI build, build-lock concurrency,
command-surface checks, report fixtures, all-agent eval fixtures, doctor, and
fresh-clone patch tests.

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
- `--keep-worktree` prints a path you can inspect.
- Missing agents or missing `entire-sem` degrade clearly without corrupting the
  repo.
- `--agent all` covers every built-in Entire coder, with Pi shown as skipped
  until a safe non-interactive launch contract exists.
