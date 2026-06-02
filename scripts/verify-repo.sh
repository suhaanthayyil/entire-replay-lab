#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 -m json.tool "$ROOT/examples/replay-run.json" >/dev/null
python3 -m json.tool "$ROOT/examples/eval-run.json" >/dev/null
python3 -m json.tool "$ROOT/schemas/replay-run.schema.json" >/dev/null
python3 -m json.tool "$ROOT/schemas/eval-run.schema.json" >/dev/null
python3 "$ROOT/scripts/validate-examples.py" >/dev/null

python3 - "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])

def load(rel):
    return json.loads((root / rel).read_text())

def require_keys(name, value, keys):
    missing = [key for key in keys if key not in value]
    if missing:
        raise SystemExit(f"{name} missing keys: {', '.join(missing)}")

replay = load("examples/replay-run.json")
require_keys("replay-run", replay, [
    "schema_version",
    "id",
    "spec",
    "agent",
    "status",
    "changed_files",
    "test",
    "metrics",
])
if replay["schema_version"] != 1:
    raise SystemExit("replay-run schema_version must be 1")
require_keys("replay-run.spec", replay["spec"], [
    "checkpoint_id",
    "prompt",
    "target_commit",
    "base_commit",
    "files_touched",
])
require_keys("replay-run.metrics", replay["metrics"], [
    "file_precision",
    "file_recall",
    "file_overlap",
    "risk_score",
    "semantic_available",
])

eval_run = load("examples/eval-run.json")
require_keys("eval-run", eval_run, [
    "schema_version",
    "id",
    "agents",
    "summaries",
    "runs",
])
if eval_run["schema_version"] != 1:
    raise SystemExit("eval-run schema_version must be 1")
for idx, summary in enumerate(eval_run["summaries"]):
    require_keys(f"eval-run.summaries[{idx}]", summary, [
        "agent",
        "runs",
        "passed",
        "failed",
        "skipped",
        "pass_rate",
        "avg_file_recall",
        "avg_file_precision",
        "avg_duration_ms",
        "risk_score",
    ])
PY

for file in \
  "$ROOT/README.md" \
  "$ROOT/docs/ACCEPTANCE.md" \
  "$ROOT/docs/ARCHITECTURE.md" \
  "$ROOT/docs/DEMO.md" \
  "$ROOT/docs/FAQ.md" \
  "$ROOT/docs/JSON_SCHEMA.md" \
  "$ROOT/docs/PRODUCT_BRIEF.md" \
  "$ROOT/docs/ROADMAP.md" \
  "$ROOT/docs/TESTING.md" \
  "$ROOT/docs/CEO_MESSAGE.md" \
  "$ROOT/patches/entire-replay-lab.patch" \
  "$ROOT/schemas/replay-run.schema.json" \
  "$ROOT/schemas/eval-run.schema.json" \
  "$ROOT/scripts/validate-examples.py"
do
  test -s "$file"
done

grep -q "The Pain It Solves" "$ROOT/README.md"
grep -q "isolated worktree" "$ROOT/README.md"
grep -q "One-Command Smoke" "$ROOT/docs/ACCEPTANCE.md"
grep -q "private benchmark" "$ROOT/docs/PRODUCT_BRIEF.md"
grep -q "Replay Lab Doctor" "$ROOT/scripts/doctor.sh"
grep -q "Validate Replay Lab example JSON" "$ROOT/scripts/validate-examples.py"
grep -q "schema_version" "$ROOT/docs/JSON_SCHEMA.md"
grep -q "cmd/entire/cli/replay.go" "$ROOT/patches/entire-replay-lab.patch"
grep -q "cmd/entire/cli/replay_test.go" "$ROOT/patches/entire-replay-lab.patch"
bash -n "$ROOT"/scripts/*.sh

echo "Replay Lab repo docs and examples look good."
