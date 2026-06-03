# FAQ

## Is this a replacement for Entire CLI?

No. Replay Lab is a prototype layer for Entire CLI. This repo carries the
implementation as a patch against a known Entire CLI base so it can be built and
tested before the feature is merged upstream.

## Why not just use generic benchmarks?

Generic benchmarks answer whether an agent is good in general. Replay Lab asks a
more useful team question: can this agent redo our real past tasks in our real
repo with our tests?

## Does it change my current worktree?

No. Replay runs create isolated git worktrees at the checkpoint base commit. The
current worktree should stay unchanged.

## Does it show the agent the original solution?

No. The replay prompt uses the original user prompt plus a short instruction to
work normally in an isolated worktree. It does not reveal the original diff.

## Do I need `entire-sem`?

No. Without `entire-sem`, replay still reports file overlap, tests, risk,
duration, and token usage when available. Semantic similarity is skipped.

## Do I need Claude Code?

Only for Claude replays. The prototype also has launchers for Codex and Gemini
CLI. `./scripts/doctor.sh` shows which launchable agents are available on your
machine.

## What if a repo has no checkpoints?

Replay Lab needs real Entire checkpoints because checkpoints provide the prompt,
target commit, base commit, and touched files. Run `entire enable`, commit the
setup files, use an agent session, commit from that session, and confirm with
`entire checkpoint list`.

## Where are reports saved?

Reports are saved inside the target repo's git common directory:

```text
.git/entire-replay/runs/
.git/entire-replay/evals/
```

They are local artifacts and are not tracked by the worktree.

## How do I test whether my machine is ready?

Build the binary, then run:

```bash
./scripts/doctor.sh /path/to/an/entire-enabled/repo
```

For a local demo repo:

```bash
./scripts/doctor.sh /path/to/entire-enabled/repo
```
