# Roadmap

## V1 Prototype

- `entire replay checkpoint <checkpoint-id>`
- `entire replay report <run-id>`
- `entire eval run`
- `entire eval report <run-id>`
- isolated git worktrees
- Claude Code, Codex, Copilot CLI, Cursor Agent CLI, Factory AI Droid,
  Gemini CLI, and OpenCode launchers
- file overlap, tests, risk, duration, tokens, and optional semantic metrics
- JSON reports under `.git/entire-replay/`

## Product V2

- Web dashboard for eval runs.
- Scheduled evals on mirrored repos.
- Checkpoint set curation by label, path, author, or date.
- Search-backed selection of similar tasks.
- Review recommendations based on replay gaps.
- Cost estimation from token usage.
- Per-agent regression history over time.

## Future Ideas

- "Agent leaderboard for this repo"
- "Find checkpoints where current best agent fails"
- "Use Replay Lab to choose the default agent for a repo"
- "Replay before upgrading an agent model"
- "Replay security-sensitive tasks only"
- "Turn good checkpoints into company-private eval suites"

## Open Questions

- Should eval artifacts sync to Entire mirrors or stay local by default?
- How should access control work for shared replay reports?
- Should Entire expose a cloud runner for teams that want scheduled evals?
- How much semantic scoring should come from `entire-sem` versus tests?
- What is the right UX for non-deterministic but acceptable alternate solutions?
