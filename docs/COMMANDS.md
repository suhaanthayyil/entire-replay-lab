# Command Reference

This repo has two command layers:

- repository helper scripts in `scripts/`
- Replay Lab commands added to the patched `entire` binary

## Repository Scripts

### `./scripts/build-cli.sh`

Builds `bin/entire` by cloning `entireio/cli`, checking out the pinned base
commit, applying `patches/entire-replay-lab.patch`, and compiling the CLI.

Useful overrides:

```bash
ENTIRE_CLI_SOURCE=/path/to/local/cli ./scripts/build-cli.sh
ENTIRE_CLI_REPO=https://github.com/<user>/cli.git ENTIRE_CLI_REF=<ref> ./scripts/build-cli.sh
```

The default repo/ref/patch values live in `scripts/replay-lab-env.sh`.

### `./scripts/check-patch.sh`

Applies the patch to a fresh temporary CLI clone and runs the Replay Lab test
slice.

```bash
./scripts/check-patch.sh
```

### `./scripts/check-command-surface.sh`

Checks that the built Replay Lab binary exposes the expected `replay` and `eval`
commands, subcommands, and required user-facing flags.

```bash
./scripts/build-cli.sh
./scripts/check-command-surface.sh
```

### `./scripts/doctor.sh [repo]`

Checks local tools, launchable agents, the built Replay Lab binary, and
optionally a target Entire-enabled repo.

```bash
./scripts/doctor.sh ~/Documents/Ultron
```

### `./scripts/smoke.sh [repo]`

Runs the main proof path:

- repo verification
- patched CLI build
- Replay/Eval command-surface checks
- doctor checks
- fresh-clone patch tests

```bash
./scripts/smoke.sh ~/Documents/Ultron
```

### `./scripts/validate-examples.py`

Validates example JSON payloads against the local schema files.

```bash
python3 ./scripts/validate-examples.py
```

### `./scripts/validate-release-docs.py`

Validates that `CHANGELOG.md` and `docs/releases/v*.md` stay in sync.

```bash
python3 ./scripts/validate-release-docs.py
```

### `./scripts/verify-reproducibility.sh`

Checks that the pinned upstream CLI repo/ref/patch path are non-empty, shared by
the build scripts, and documented consistently.

```bash
./scripts/verify-reproducibility.sh
```

### `./scripts/verify-patch-manifest.sh`

Checks that the Replay Lab patch only touches the expected upstream files and
includes the replay command/test anchors.

```bash
./scripts/verify-patch-manifest.sh
```

### `./scripts/verify-release-state.sh`

After publishing a release, checks that `docs/releases/v*.md`, local git tags,
and published GitHub releases match.

```bash
./scripts/verify-release-state.sh
```

### `./scripts/refresh-patch.sh`

Regenerates `patches/entire-replay-lab.patch` from a local CLI checkout.

```bash
ENTIRE_CLI_SOURCE=/path/to/cli-replay-lab ./scripts/refresh-patch.sh
```

### `./scripts/clean.sh`

Removes generated `bin/` and `tmp/` artifacts.

```bash
./scripts/clean.sh
```

## Patched Entire Commands

Build first:

```bash
./scripts/build-cli.sh
```

### `entire replay checkpoint`

Replay one checkpoint with one launchable agent.

```bash
./bin/entire replay checkpoint <checkpoint-id> \
  --agent claude-code \
  --test-cmd "<repo test command>" \
  --keep-worktree
```

Useful flags:

- `--agent claude-code|codex|gemini`
- `--model <model>`
- `--test-cmd <command>`
- `--keep-worktree`
- `--json`
- `--timeout <duration>`

### `entire replay report`

Render a saved replay run.

```bash
./bin/entire replay report <run-id>
./bin/entire replay report <run-id> --json
```

### `entire eval run`

Run multiple checkpoint replays and rank agents.

```bash
./bin/entire eval run \
  --from-checkpoints \
  --limit 3 \
  --agent claude-code,codex \
  --test-cmd "<repo test command>"
```

Useful flags:

- `--checkpoint <id>` repeatable
- `--from-checkpoints`
- `--limit <n>`
- `--agent <agents>`
- `--model <model>`
- `--test-cmd <command>`
- `--keep-worktree`
- `--json`
- `--timeout <duration>`

### `entire eval report`

Render a saved eval run.

```bash
./bin/entire eval report <run-id>
./bin/entire eval report <run-id> --json
```
