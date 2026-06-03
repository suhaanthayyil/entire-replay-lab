# Entire Replay Lab

[![CI](https://github.com/suhaanthayyil/entire-replay-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/suhaanthayyil/entire-replay-lab/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Prototype](https://img.shields.io/badge/status-prototype-orange.svg)](docs/ROADMAP.md)

Private, repo-specific agent evaluation from real Entire checkpoints.

Replay Lab turns past agent work into repeatable eval tasks. It checks out the
checkpoint's pre-change commit in an isolated worktree, reruns the original
prompt with a selected coding agent, then compares the new result to the real
commit that landed.

## The Pain It Solves

Teams usually judge coding agents with vibes, generic benchmarks, or one-off
experiments. None of those answer the question that matters:

> Which agent is best on our real repo, our real tasks, and our real tests?

Entire already captures the raw material for that answer: checkpoints,
sessions, prompts, commits, touched files, token metadata, and transcripts.
Replay Lab turns that history into a private benchmark suite without sending
repo context to a public eval dataset.

## What It Does

- Replays a real checkpoint in a temp git worktree at the original base commit.
- Runs Claude Code, Codex, or Gemini CLI against the original prompt.
- Compares the replayed output against the original target commit.
- Reports file overlap, optional test status, semantic similarity, risky files,
  duration, and token usage when available.
- Saves machine-readable JSON under the repo's git common directory, not in the
  tracked worktree.
- Never mutates the user's current working tree.

## Current Status

This repo is the product and demo home for the prototype.

The runnable implementation is captured in `patches/entire-replay-lab.patch`.
The build script applies it to a known Entire CLI base commit and then builds a
local `entire` binary.

- Default repo: `https://github.com/entireio/cli.git`
- Default ref: `e858fb537e70b8008a10f712cb73588cb67aacf2`
- Patch: `patches/entire-replay-lab.patch`
- Commands added there: `entire replay` and `entire eval`

The pinned build inputs are centralized in `scripts/replay-lab-env.sh` and
checked by [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md).

## Quick Start

Build the Replay Lab-enabled Entire CLI:

```bash
git clone https://github.com/suhaanthayyil/entire-replay-lab.git
cd entire-replay-lab
./scripts/build-cli.sh
```

By default the script clones `entireio/cli`, checks out the tested base commit,
applies `patches/entire-replay-lab.patch`, and builds `bin/entire`.

To build from a local CLI checkout that already has Replay Lab applied:

```bash
ENTIRE_CLI_SOURCE=/path/to/cli-replay-lab ./scripts/build-cli.sh
```

Then run it inside a repo that already has Entire checkpoints:

```bash
cd ~/Documents/Ultron
entire checkpoint list

/path/to/entire-replay-lab/bin/entire replay checkpoint <checkpoint-id> \
  --agent claude-code \
  --test-cmd "python3 -m pytest" \
  --keep-worktree
```

Run a small private eval over recent checkpoints:

```bash
/path/to/entire-replay-lab/bin/entire eval run \
  --from-checkpoints \
  --limit 3 \
  --agent claude-code,codex \
  --test-cmd "python3 -m pytest"
```

Reopen saved reports:

```bash
/path/to/entire-replay-lab/bin/entire replay report <run-id>
/path/to/entire-replay-lab/bin/entire eval report <run-id>
```

Check your machine before a live replay:

```bash
./scripts/doctor.sh /path/to/entire-enabled/repo
```

Run the full local smoke check:

```bash
./scripts/smoke.sh /path/to/entire-enabled/repo
```

For all commands, see [docs/COMMANDS.md](docs/COMMANDS.md).

## Example Output

```text
Replay rpl_7a1d4c9e
checkpoint 9a91ce5c55f2 - agent claude-code - status passed

Range: a77cd65..2f9c481
Files: recall 100% - precision 100% - overlap 3/3
Tests: passed - python3 -m pytest
Semantic: 86% semantic match
Risk: 1 - missing tests
Saved: .git/entire-replay/runs/rpl_7a1d4c9e.json
```

```text
Replay Eval evl_a12c0f44

Agent Ranking
Agent               Runs  Pass   Recall   Prec.   Risk  Duration  Tokens
------------------------------------------------------------------------
claude-code            3   100%     92%     88%      1     2m14s  48k in / 9k out
codex                  3    67%     80%     91%      3     1m41s  35k in / 7k out
```

## Why People Should Use It

Replay Lab answers practical questions that teams cannot get from normal git
history:

- Which coding agent actually reproduces our past successful work?
- Which model is faster or cheaper on our repo without sacrificing quality?
- Which agent touches too many extra files?
- Which checkpoint tasks are good internal eval cases?
- Where did an agent pass tests but still miss the semantic intent?

It makes agent adoption measurable using the team's own historical work.

## Safety Defaults

- Replays run in isolated temp worktrees.
- The current worktree is never modified.
- Test commands are opt-in.
- Replay prompts do not reveal the original target diff.
- Missing `entire-sem` only disables semantic scoring.
- Result JSON is stored under `.git/entire-replay/`.

## Repository Layout

```text
docs/
  ACCEPTANCE.md        Evidence checklist for build, patch, doctor, and live use
  ARCHITECTURE.md      How replay data flows through Entire
  COMMANDS.md          Script and patched Entire command reference
  DEMO.md              CEO/demo script and commands
  FAQ.md               Common setup and safety questions
  JSON_SCHEMA.md       Stable v1 result shape
  PRODUCT_BRIEF.md     Pain, solution, audience, and demo hook
  RELEASE.md           Release checklist and tagging flow
  REPRODUCIBILITY.md   Pinned upstream base and patch verification
  ROADMAP.md           MVP, product path, and open questions
  TESTING.md           Validation levels and live-test commands
examples/
  replay-run.json      Example checkpoint replay result
  eval-run.json        Example multi-agent eval result
schemas/
  replay-run.schema.json
  eval-run.schema.json
patches/
  entire-replay-lab.patch
scripts/
  build-cli.sh         Build the Replay Lab CLI branch
  check-patch.sh       Apply the patch to a fresh CLI clone and run Replay tests
  clean.sh             Remove generated build artifacts
  demo-commands.sh     Print commands for a real Entire-enabled repo
  doctor.sh            Preflight local tools, agents, binary, and target repo
  refresh-patch.sh     Regenerate the patch from a local CLI checkout
  release-check.sh     Run release-ready verification without live agent use
  replay-lab-env.sh    Shared pinned Entire CLI repo/ref/patch defaults
  smoke.sh             Run repo verify, build, doctor, and patch tests
  validate-doc-links.py Validate local Markdown links and anchors
  validate-examples.py Validate example JSON against local schemas
  validate-release-docs.py Validate changelog and release-note consistency
  verify-release-state.sh Check docs, tags, and GitHub releases after publishing
  verify-reproducibility.sh Check pinned build inputs stay in sync
  verify-repo.sh       Validate docs and JSON examples
```

## Related Entire Building Blocks

- Checkpoints provide the original prompt, session, target commit, and files.
- Repo mirrors make this valuable as infrastructure, not just local tooling.
- `entire-sem` adds semantic similarity over changed entities.
- `entire blame` and `entire why` explain the provenance of replayed lines.
- Entire Search can later find related replay tasks and historical decisions.

## License

MIT.
