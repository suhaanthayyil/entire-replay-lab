# Testing

Replay Lab has three levels of validation.

## Repo Validation

Run this before committing docs, schemas, or scripts:

```bash
./scripts/verify-repo.sh
```

It checks:

- JSON examples parse successfully.
- JSON examples contain the expected v1 keys.
- Schemas parse successfully.
- Main docs exist and include the important setup sections.
- Shell scripts pass `bash -n`.

## Build Validation

Build the Replay Lab-enabled Entire CLI:

```bash
./scripts/build-cli.sh
```

By default this clones `entireio/cli`, checks out the tested base commit, applies
the included Replay Lab patch, and builds `bin/entire`.

```text
https://github.com/entireio/cli.git@e858fb537e70b8008a10f712cb73588cb67aacf2
patches/entire-replay-lab.patch
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

## Live Validation

Use a repo that already has Entire checkpoints:

```bash
cd ~/Documents/Ultron
entire checkpoint list
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
