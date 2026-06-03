#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${1:-/path/to/entire-enabled/repo}"
ENTIRE_BIN="${ENTIRE_BIN:-$ROOT/bin/entire}"
TEST_CMD="${TEST_CMD:-python3 -m pytest}"

cat <<EOF
cd "$REPO"

# Pick a real checkpoint.
entire checkpoint list

# Replay one checkpoint safely in an isolated worktree.
"$ENTIRE_BIN" replay checkpoint <checkpoint-id> \\
  --agent claude-code \\
  --test-cmd "$TEST_CMD" \\
  --keep-worktree

# Compare agents across recent checkpoint tasks.
"$ENTIRE_BIN" eval run \\
  --from-checkpoints \\
  --limit 3 \\
  --agent all \\
  --test-cmd "$TEST_CMD"

# Reopen saved reports.
"$ENTIRE_BIN" replay report <run-id>
"$ENTIRE_BIN" eval report <eval-id>
EOF
