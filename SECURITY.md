# Security

Replay Lab runs coding agents and optional test commands in isolated git
worktrees, but those commands can still execute arbitrary local code.

## Safe Use

- Run Replay Lab only on repositories you trust.
- Review `--test-cmd` before running it.
- Do not replay prompts that contain secrets.
- Use `--keep-worktree` only when you need to inspect artifacts.
- Delete preserved worktrees after inspection.

## Data Handling

- Replay JSON is stored under `.git/entire-replay/` in the target repository.
- The current worktree is not modified by replay runs.
- The original target diff is not included in the replay prompt.
- Missing `entire-sem` disables semantic scoring instead of sending data to a
  network service.

## Reporting Issues

Open a private issue or contact the maintainer if Replay Lab mutates the current
worktree, exposes checkpoint metadata unexpectedly, or writes reports outside
the git common directory.
