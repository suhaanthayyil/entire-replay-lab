#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTIRE_BIN="${ENTIRE_BIN:-$ROOT/bin/entire}"
CLI_SOURCE="${ENTIRE_CLI_SOURCE:-$ROOT/tmp/cli}"

if [[ ! -x "$ENTIRE_BIN" ]]; then
  echo "Replay Lab binary is not executable: $ENTIRE_BIN" >&2
  echo "Run ./scripts/build-cli.sh first, or set ENTIRE_BIN=/path/to/entire." >&2
  exit 1
fi

if [[ ! -d "$CLI_SOURCE/.git" ]]; then
  echo "Patched Entire CLI source is missing: $CLI_SOURCE" >&2
  echo "Run ./scripts/build-cli.sh first, or set ENTIRE_CLI_SOURCE=/path/to/cli." >&2
  exit 1
fi

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/entire-replay-all-agent.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

REPO="$WORKDIR/repo"
CHECKPOINT_ID="a1b2c3d4e5f6"
SAFE_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

git init --quiet "$REPO"
git -C "$REPO" config user.name "Replay Lab Fixture"
git -C "$REPO" config user.email "replay-lab@example.com"

mkdir -p "$REPO/src"
cat >"$REPO/src/auth.py" <<'PY'
def validate_token(token):
    return bool(token)
PY
git -C "$REPO" add src/auth.py
git -C "$REPO" commit --quiet --no-gpg-sign -m "initial auth"

cat >"$REPO/src/auth.py" <<'PY'
def validate_token(token, *, issuer=None):
    if not token:
        return False
    return issuer is None or issuer == "fixture"
PY
git -C "$REPO" add src/auth.py
git -C "$REPO" commit --quiet --no-gpg-sign \
  -m "update auth validation" \
  -m "Entire-Checkpoint: $CHECKPOINT_ID"

FIXTURE_WRITER="$WORKDIR/write_checkpoint.go"
cat >"$FIXTURE_WRITER" <<'GO'
package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/entireio/cli/cmd/entire/cli/agent"
	"github.com/entireio/cli/cmd/entire/cli/checkpoint"
	checkpointid "github.com/entireio/cli/cmd/entire/cli/checkpoint/id"
	"github.com/entireio/cli/redact"
	git "github.com/go-git/go-git/v6"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "usage: %s <repo> <checkpoint-id>\n", os.Args[0])
		os.Exit(2)
	}
	repoRoot := os.Args[1]
	cpID := checkpointid.MustCheckpointID(os.Args[2])

	repo, err := git.PlainOpen(repoRoot)
	if err != nil {
		fmt.Fprintf(os.Stderr, "open repo: %v\n", err)
		os.Exit(1)
	}

	transcript := []byte(`{"type":"user","uuid":"fixture-user","message":{"content":"Update auth validation."}}` + "\n")
	err = checkpoint.NewGitStore(repo).WriteCommitted(context.Background(), checkpoint.WriteCommittedOptions{
		CheckpointID:     cpID,
		SessionID:        "replay-lab-fixture-session",
		CreatedAt:        time.Date(2026, 6, 3, 0, 0, 0, 0, time.UTC),
		Strategy:         "manual-commit",
		Branch:           "master",
		Transcript:       redact.AlreadyRedacted(transcript),
		Prompts:          []string{"Update auth validation."},
		FilesTouched:     []string{"src/auth.py"},
		CheckpointsCount: 1,
		Agent:            agent.AgentTypeClaudeCode,
		Model:            "fixture-model",
		AuthorName:       "Replay Lab Fixture",
		AuthorEmail:      "replay-lab@example.com",
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "write checkpoint: %v\n", err)
		os.Exit(1)
	}
}
GO

go -C "$CLI_SOURCE" run "$FIXTURE_WRITER" "$REPO" "$CHECKPOINT_ID"

EVAL_JSON="$WORKDIR/eval.json"
(
  cd "$REPO"
  PATH="$SAFE_PATH" "$ENTIRE_BIN" eval run --checkpoint "$CHECKPOINT_ID" --agent all --json >"$EVAL_JSON"
)

python3 - "$EVAL_JSON" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
expected_agents = [
    "claude-code",
    "codex",
    "gemini",
    "cursor",
    "copilot-cli",
    "opencode",
    "factoryai-droid",
    "pi",
]

if data.get("agents") != expected_agents:
    raise SystemExit(f"agents mismatch: {data.get('agents')!r}")

runs = data.get("runs", [])
if len(runs) != len(expected_agents):
    raise SystemExit(f"run count mismatch: got {len(runs)}, want {len(expected_agents)}")

by_agent = {run.get("agent"): run for run in runs}
if set(by_agent) != set(expected_agents):
    raise SystemExit(f"run agents mismatch: {sorted(by_agent)!r}")

launchable = {"claude-code", "codex", "gemini"}
session_only = set(expected_agents) - launchable
for agent_name in expected_agents:
    run = by_agent[agent_name]
    if run.get("status") != "skipped":
        raise SystemExit(f"{agent_name}: status = {run.get('status')!r}, want skipped")
    if run.get("test", {}).get("status") != "skipped":
        raise SystemExit(f"{agent_name}: test status = {run.get('test', {}).get('status')!r}, want skipped")
    error = run.get("error", "")
    if agent_name in launchable and "requires" not in error:
        raise SystemExit(f"{agent_name}: missing command error should mention requires: {error!r}")
    if agent_name in session_only and "supported by Entire but is not launchable" not in error:
        raise SystemExit(f"{agent_name}: session-only error mismatch: {error!r}")

summaries = data.get("summaries", [])
if {summary.get("agent") for summary in summaries} != set(expected_agents):
    raise SystemExit("summaries do not cover every expected agent")
if any(summary.get("skipped") != 1 for summary in summaries):
    raise SystemExit(f"expected every summary to count one skipped run: {summaries!r}")

print(f"OK all-agent eval expanded {len(expected_agents)} coders and saved {data.get('id')}")
PY

python3 "$ROOT/scripts/validate-examples.py" \
  --check "$EVAL_JSON" "$ROOT/schemas/eval-run.schema.json"

EVAL_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["id"])' "$EVAL_JSON")"
REPORT_TEXT="$WORKDIR/eval-report.txt"
(
  cd "$REPO"
  "$ENTIRE_BIN" eval report "$EVAL_ID" >"$REPORT_TEXT"
)

for agent_name in claude-code codex gemini cursor copilot-cli opencode factoryai-droid pi; do
  if ! grep -Fq "$agent_name" "$REPORT_TEXT"; then
    echo "Rendered eval report is missing $agent_name" >&2
    exit 1
  fi
done

echo "OK all-agent eval command fixture renders every built-in Entire coder."
