# Acceptance Checklist

Replay Lab is useful only if it can be built, inspected, and tested by someone
who did not work on the prototype. This checklist maps the expected behavior to
local evidence.

## Repository Is Self-Contained

Evidence:

```bash
./scripts/verify-repo.sh
python3 ./scripts/validate-examples.py
./scripts/verify-reproducibility.sh
./scripts/verify-patch-manifest.sh
```

Proves:

- docs and examples exist
- example JSON parses and validates against the local schemas
- schemas parse
- patch file exists and includes Replay Lab implementation files
- patch file only touches the expected upstream files
- pinned upstream base and patch metadata stay in sync
- scripts pass shell syntax checks

## Patch Applies To A Known CLI Base

Evidence:

```bash
./scripts/check-patch.sh
```

Proves:

- a fresh `entireio/cli` clone can check out the known base
- `patches/entire-replay-lab.patch` applies cleanly
- the Replay Lab test slice passes in that patched checkout

## Replay Lab Binary Builds

Evidence:

```bash
./scripts/build-cli.sh
./scripts/check-command-surface.sh
./scripts/check-report-fixtures.sh
./bin/entire replay --help
./bin/entire eval --help
```

Proves:

- the patched CLI compiles
- `entire replay` is registered
- `entire eval` is registered
- replay/eval subcommands expose help output
- required replay/eval flags such as `--agent`, `--test-cmd`,
  `--keep-worktree`, `--checkpoint`, `--from-checkpoints`, and `--json` are
  present
- saved replay/eval reports can be rendered from result JSON in text and
  schema-valid JSON modes
- eval report schemas validate embedded replay runs with the same ReplayRun
  contract used for standalone replay reports

## Local Machine Is Ready For A Live Replay

Evidence:

```bash
./scripts/doctor.sh /path/to/entire-enabled/repo
```

Proves:

- required local tools are installed
- launchable agents are present or clearly reported missing
- the built binary has Replay Lab commands
- the target repo is a git repo
- Entire settings and checkpoints can be detected

## One-Command Smoke

Evidence:

```bash
./scripts/smoke.sh /path/to/entire-enabled/repo
```

Proves the full local happy path:

- repository verification
- patched CLI build
- command-surface checks
- saved report fixture checks
- local doctor checks
- fresh-clone patch test

## Live Replay Acceptance

Use a real checkpoint id from:

```bash
cd /path/to/entire-enabled/repo
entire checkpoint list
```

Then run:

```bash
/path/to/entire-replay-lab/bin/entire replay checkpoint <checkpoint-id> \
  --agent claude-code \
  --test-cmd "<repo test command>" \
  --keep-worktree
```

Expected:

- the current worktree remains unchanged
- replay creates an isolated worktree
- output includes checkpoint, agent, status, commit range, file metrics, test
  status, optional semantic similarity, risk, and saved report path
- saved JSON appears under `.git/entire-replay/runs/`

## Multi-Agent Eval Acceptance

```bash
/path/to/entire-replay-lab/bin/entire eval run \
  --from-checkpoints \
  --limit 3 \
  --agent claude-code,codex \
  --test-cmd "<repo test command>"
```

Expected:

- each selected checkpoint becomes a replay task
- unsupported or missing agents are skipped clearly
- agents are ranked by pass rate, file overlap, risk, duration, and tokens when
  available
- saved JSON appears under `.git/entire-replay/evals/`
