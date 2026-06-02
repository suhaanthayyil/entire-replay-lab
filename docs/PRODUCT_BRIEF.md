# Product Brief

## One Sentence

Entire Replay Lab turns real checkpoint history into a private benchmark for
coding agents.

## Pain

Teams do not know which agent is best for their repo. Public benchmarks are too
generic, one-off demos are easy to overfit, and manual judgment is mostly vibes.

## Solution

Use the work Entire already captured. For each checkpoint, Replay Lab reconstructs
the original task:

- base commit
- original prompt
- target commit
- touched files
- agent/session metadata

Then it reruns the prompt in an isolated worktree with a selected agent and
compares the result against the real committed outcome.

## Why Entire Is Uniquely Positioned

Entire has the provenance layer most tools are missing:

- checkpoints know what changed and why
- sessions preserve agent intent and output
- git commits provide exact before/after states
- `entire-sem` can compare semantic changes
- `entire blame` and `entire why` explain line-level ownership

Replay Lab turns that provenance into measurable agent quality.

## Who Uses It

- engineering leads choosing a default coding agent
- platform teams comparing models before rollout
- founders showing agent quality on real work
- teams building private eval suites from their own history

## Demo Hook

> Instead of asking whether Claude or Codex is better in general, Replay Lab asks
> whether they can redo last week's real auth refactor in this repo, pass our
> tests, and avoid touching unrelated files.
