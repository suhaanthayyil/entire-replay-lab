# Command Reference

This repo has two command layers:

- repository helper scripts in `scripts/`
- Replay Lab commands added to the patched `entire` binary

## Repository Scripts

### `./scripts/build-cli.sh`

Builds `bin/entire` by cloning `entireio/cli`, checking out the pinned base
commit, applying `patches/entire-replay-lab.patch`, and compiling the CLI.
Builds take a repo-local lock under `tmp/` so concurrent smoke, release, and
manual build runs do not mutate the shared patched checkout at the same time.

Useful overrides:

```bash
ENTIRE_CLI_SOURCE=/path/to/local/cli ./scripts/build-cli.sh
ENTIRE_CLI_REPO=https://github.com/<user>/cli.git ENTIRE_CLI_REF=<ref> ./scripts/build-cli.sh
ENTIRE_BUILD_LOCK_TIMEOUT=60 ./scripts/build-cli.sh
```

The default repo/ref/patch values live in `scripts/replay-lab-env.sh`.

### `./scripts/check-build-lock.sh`

Runs two `build-cli.sh` invocations concurrently and verifies the repo-local
build lock serializes access to the shared patched checkout safely. It also
checks stale-lock cleanup and active-lock timeout behavior.

```bash
./scripts/check-build-lock.sh
```

### `./scripts/verify-repo.sh`

Runs the fast repository checks for docs, examples, schemas, metadata,
portability, release-note consistency, reproducibility metadata, and patch
manifest sanity.

```bash
./scripts/verify-repo.sh
```

### `./scripts/replay-lab-env.sh`

Sourceable helper that stores the pinned upstream Entire CLI repo, ref, patch
path, and expected patch SHA-256 used by build and verification scripts.

```bash
./scripts/replay-lab-env.sh
```

### `./scripts/check-patch.sh`

Applies the patch to a fresh temporary CLI clone and runs the Replay Lab test
slice.

```bash
./scripts/check-patch.sh
```

### `./scripts/check-command-surface.sh`

Checks that the built Replay Lab binary exposes the expected `replay` and `eval`
commands, subcommands, required user-facing flags, and important CLI
negative-path errors such as invalid replay agents and non-positive
`--from-checkpoints --limit` values.

```bash
./scripts/build-cli.sh
./scripts/check-command-surface.sh
```

### `./scripts/check-report-fixtures.sh`

Seeds example replay/eval result JSON into a temporary git repo and verifies the
built Replay Lab binary can render both text and schema-valid `--json` reports.
It also verifies missing replay/eval report IDs fail clearly in both normal and
`--json` modes.

```bash
./scripts/build-cli.sh
./scripts/check-report-fixtures.sh
```

### `./scripts/check-all-agent-eval.sh`

Creates a temporary git repo with a real committed Entire checkpoint, runs the
built Replay Lab binary with `entire eval run --agent all --json`, validates the
generated JSON against the eval schema, and confirms the rendered report lists
every built-in Entire coder. Live agent binaries are hidden from `PATH` during
the eval, so this proves expansion and skipped-run behavior without spending
model calls.

```bash
./scripts/build-cli.sh
./scripts/check-all-agent-eval.sh
```

### `./scripts/doctor.sh [repo]`

Checks local tools, launchable agents, the built Replay Lab binary, and
optionally a target Entire-enabled repo.

```bash
./scripts/doctor.sh /path/to/entire-enabled/repo
```

### `./scripts/smoke.sh [repo]`

Runs the main proof path:

- repo verification
- patched CLI build
- build lock concurrency
- Replay/Eval command-surface checks
- all-agent eval fixture
- doctor checks
- fresh-clone patch tests

```bash
./scripts/smoke.sh /path/to/entire-enabled/repo
```

### `./scripts/demo-commands.sh [repo]`

Prints a copy/paste demo sequence for a repo with Entire checkpoints. It does
not run the replay itself.

```bash
./scripts/demo-commands.sh /path/to/entire-enabled/repo
```

### `./scripts/release-check.sh`

Runs the release-ready proof path: repo validators, reproducibility checks,
patched CLI build, build-lock concurrency, command surface checks, report
fixtures, the all-agent eval fixture, and patch tests.

```bash
./scripts/release-check.sh
```

### `./scripts/validate-examples.py`

Validates example JSON payloads against the local schema files, including local
cross-schema references and eval summary consistency. It can also validate
explicit JSON/schema pairs.

```bash
python3 ./scripts/validate-examples.py
python3 ./scripts/validate-examples.py --check /path/to/report.json schemas/replay-run.schema.json
```

### `./scripts/validate-project-metadata.py`

Validates the README badges, MIT license text, prototype positioning, and basic
license hygiene so the repo stays easy for Entire to inspect and reuse.

```bash
python3 ./scripts/validate-project-metadata.py
```

### `./scripts/validate-doc-links.py`

Validates local Markdown links and heading anchors across README and docs.

```bash
python3 ./scripts/validate-doc-links.py
```

### `./scripts/validate-markdown-fences.py`

Validates Markdown fenced code blocks, allowed fence languages, and JSON fence
syntax across README and docs.

```bash
python3 ./scripts/validate-markdown-fences.py
```

### `./scripts/validate-portability.py`

Validates that reusable docs and scripts avoid machine-specific local paths.
Historical release notes are skipped because they intentionally record the
local evidence command that was run.

```bash
python3 ./scripts/validate-portability.py
```

### `./scripts/validate-script-hygiene.py`

Validates helper script shebangs, executable bits, shell safety flags, Python
entrypoints, and command-reference coverage.

```bash
python3 ./scripts/validate-script-hygiene.py
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

Regenerates `patches/entire-replay-lab.patch` from a local CLI checkout. The
helper diffs the current checkout against the pinned upstream base and includes
new Replay Lab files without changing that checkout's real git index.

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

- `--agent claude-code|codex|copilot-cli|cursor|factoryai-droid|gemini|opencode`
- `--model <model>`
- `--test-cmd <command>`
- `--keep-worktree`
- `--json`
- `--timeout <duration>`

`replay checkpoint` runs exactly one launchable agent. Use `eval run
--agent all` when you want coverage across every built-in Entire coder.

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
  --agent all \
  --test-cmd "<repo test command>"
```

Useful flags:

- `--checkpoint <id>` repeatable
- `--from-checkpoints`
- `--limit <n>` positive checkpoint count for `--from-checkpoints`
- `--agent <agents>` or `--agent all`
- `--model <model>`
- `--test-cmd <command>`
- `--keep-worktree`
- `--json`
- `--timeout <duration>`

`--agent all` expands from Entire's user-facing built-in coder registry. Today
that is `claude-code`, `codex`, `copilot-cli`, `cursor`, `factoryai-droid`,
`gemini`, `opencode`, and `pi`. Replay Lab can launch Claude Code, Codex,
Copilot CLI, Cursor Agent CLI, Factory AI Droid, Gemini CLI, and OpenCode when
their local binaries are installed and authenticated. Pi stays in the eval as a
skipped row until Pi exposes a safe non-interactive launch contract.
Common aliases are accepted for convenience: `gemini-cli`, `cursor-cli`, and
`copilot`.

### `entire eval report`

Render a saved eval run.

```bash
./bin/entire eval report <run-id>
./bin/entire eval report <run-id> --json
```
