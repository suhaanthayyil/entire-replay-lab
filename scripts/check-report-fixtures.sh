#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTIRE_BIN="${ENTIRE_BIN:-$ROOT/bin/entire}"

if [[ ! -x "$ENTIRE_BIN" ]]; then
  echo "Replay Lab binary is not executable: $ENTIRE_BIN" >&2
  echo "Run ./scripts/build-cli.sh first, or set ENTIRE_BIN=/path/to/entire." >&2
  exit 1
fi

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/entire-replay-report-fixtures.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

REPO="$WORKDIR/repo"
git init --quiet "$REPO"
git -C "$REPO" config user.name "Replay Lab Fixture"
git -C "$REPO" config user.email "replay-lab@example.com"
printf 'fixture\n' >"$REPO/README.md"
git -C "$REPO" add README.md
git -C "$REPO" commit --quiet --no-gpg-sign -m "fixture repo"

COMMON_DIR="$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir)"
mkdir -p "$COMMON_DIR/entire-replay/runs" "$COMMON_DIR/entire-replay/evals"
cp "$ROOT/examples/replay-run.json" "$COMMON_DIR/entire-replay/runs/rpl_7a1d4c9e.json"
cp "$ROOT/examples/eval-run.json" "$COMMON_DIR/entire-replay/evals/evl_a12c0f44.json"

REPLAY_TEXT="$WORKDIR/replay.txt"
REPLAY_JSON="$WORKDIR/replay.json"
EVAL_TEXT="$WORKDIR/eval.txt"
EVAL_JSON="$WORKDIR/eval.json"

(cd "$REPO" && "$ENTIRE_BIN" replay report rpl_7a1d4c9e >"$REPLAY_TEXT")
(cd "$REPO" && "$ENTIRE_BIN" replay report rpl_7a1d4c9e --json >"$REPLAY_JSON")
(cd "$REPO" && "$ENTIRE_BIN" eval report evl_a12c0f44 >"$EVAL_TEXT")
(cd "$REPO" && "$ENTIRE_BIN" eval report evl_a12c0f44 --json >"$EVAL_JSON")

grep -Fq "Replay" "$REPLAY_TEXT"
grep -Fq "rpl_7a1d4c9e" "$REPLAY_TEXT"
grep -Fq "checkpoint 9a91ce5c55f2" "$REPLAY_TEXT"
grep -Fq "Replay Eval" "$EVAL_TEXT"
grep -Fq "evl_a12c0f44" "$EVAL_TEXT"

python3 - "$REPLAY_JSON" "$EVAL_JSON" <<'PY'
import json
import sys
from pathlib import Path

replay = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
eval_run = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

if replay.get("id") != "rpl_7a1d4c9e":
    raise SystemExit("replay report JSON returned the wrong id")
if replay.get("schema_version") != 1:
    raise SystemExit("replay report JSON returned the wrong schema_version")
if replay.get("spec", {}).get("checkpoint_id") != "9a91ce5c55f2":
    raise SystemExit("replay report JSON returned the wrong checkpoint")
if replay.get("result_path", "").endswith("rpl_7a1d4c9e.json") is False:
    raise SystemExit("replay report JSON did not populate result_path")

if eval_run.get("id") != "evl_a12c0f44":
    raise SystemExit("eval report JSON returned the wrong id")
if eval_run.get("schema_version") != 1:
    raise SystemExit("eval report JSON returned the wrong schema_version")
if [summary.get("agent") for summary in eval_run.get("summaries", [])] != ["claude-code", "codex", "pi"]:
    raise SystemExit("eval report JSON returned unexpected summaries")
if len(eval_run.get("runs", [])) != 3:
    raise SystemExit("eval report JSON did not preserve embedded replay runs")
first_run = eval_run["runs"][0]
if first_run.get("id") != "rpl_7a1d4c9e":
    raise SystemExit("eval report JSON returned unexpected first embedded replay run")
subagent_tokens = first_run.get("token_usage", {}).get("subagent_tokens", {})
if subagent_tokens.get("input_tokens") != 1200:
    raise SystemExit("eval report JSON did not preserve recursive token usage")
if eval_run.get("result_path", "").endswith("evl_a12c0f44.json") is False:
    raise SystemExit("eval report JSON did not populate result_path")
PY

python3 "$ROOT/scripts/validate-examples.py" \
  --check "$REPLAY_JSON" "$ROOT/schemas/replay-run.schema.json" \
  --check "$EVAL_JSON" "$ROOT/schemas/eval-run.schema.json"

echo "OK Replay/Eval report fixture commands render text and schema-valid JSON."
