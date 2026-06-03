# Demo

This demo is designed for an Entire-enabled repo with real checkpoints.

## What To Show

The shortest pitch:

> Entire can replay a real past checkpoint, run an agent again in a safe
> worktree, and tell us whether the agent reproduced the original change.

## Setup

Build the Replay Lab-enabled CLI:

```bash
cd /path/to/entire-replay-lab
./scripts/build-cli.sh
```

Choose a repo with checkpoints:

```bash
cd /path/to/entire-enabled/repo
entire checkpoint list
```

Pick a checkpoint id from the list.

## One Checkpoint Replay

```bash
/path/to/entire-replay-lab/bin/entire replay checkpoint <checkpoint-id> \
  --agent claude-code \
  --test-cmd "python3 -m pytest" \
  --keep-worktree
```

Point out:

- it used the original prompt
- it ran away from the current worktree
- it compared back to the original commit
- it produced file, test, semantic, risk, duration, and token signals

## Multi-Agent Eval

```bash
/path/to/entire-replay-lab/bin/entire eval run \
  --from-checkpoints \
  --limit 3 \
  --agent claude-code,codex \
  --test-cmd "python3 -m pytest"
```

Point out:

- the tasks come from real Entire checkpoints
- every agent gets the same historical prompt
- the report ranks agents on repo-specific performance

## Saved Reports

```bash
/path/to/entire-replay-lab/bin/entire replay report <run-id>
/path/to/entire-replay-lab/bin/entire eval report <eval-id>
```

For JSON:

```bash
/path/to/entire-replay-lab/bin/entire replay report <run-id> --json
/path/to/entire-replay-lab/bin/entire eval report <eval-id> --json
```

## CEO-Friendly Use Case

Generic agent benchmarks do not tell a team which agent works best in their own
codebase. Replay Lab turns the team's real checkpoint history into a private
benchmark, so they can choose agents with evidence instead of vibes.
