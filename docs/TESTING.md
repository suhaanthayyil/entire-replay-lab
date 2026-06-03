# Testing

Replay Lab has three levels of validation.

## Repo Validation

Run this before committing docs, schemas, or scripts:

```bash
./scripts/verify-repo.sh
```

It checks:

- JSON examples parse successfully.
- JSON examples validate against the local schemas.
- Schemas parse successfully.
- Main docs exist and include the important setup sections.
- Local Markdown links and anchors resolve.
- Changelog and release-note files stay in sync.
- Reproducibility metadata is in sync.
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

After publishing a release, verify release docs, local tags, and GitHub releases:

```bash
./scripts/verify-release-state.sh
```

To use a local CLI checkout that already has Replay Lab applied:

```bash
ENTIRE_CLI_SOURCE=/Users/suhaan/Documents/Coding/cli-replay-lab ./scripts/build-cli.sh
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
ENTIRE_CLI_SOURCE=/Users/suhaan/Documents/Coding/cli-replay-lab ./scripts/refresh-patch.sh
```

Remove generated binaries and temp clones:

```bash
./scripts/clean.sh
```

## Smoke Validation

Run the main local proof path:

```bash
./scripts/smoke.sh ~/Documents/Ultron
```

This runs repo verification, patched CLI build, command-surface checks, doctor,
and fresh-clone patch tests.

## Live Validation

Use a repo that already has Entire checkpoints:

```bash
cd ~/Documents/Ultron
entire checkpoint list
```

Before running an agent replay, check local prerequisites:

```bash
./scripts/doctor.sh ~/Documents/Ultron
```

Replay one checkpoint:

```bash
/Users/suhaan/Documents/Coding/entire-replay-lab/bin/entire replay checkpoint <checkpoint-id> \
  --agent claude-code \
  --test-cmd "python3 -m pytest" \
  --keep-worktree
```

Run a small eval:

```bash
/Users/suhaan/Documents/Coding/entire-replay-lab/bin/entire eval run \
  --from-checkpoints \
  --limit 3 \
  --agent claude-code,codex \
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
