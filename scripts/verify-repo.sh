#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_file() {
  local file="$1"
  if [[ ! -s "$file" ]]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
}

require_contains() {
  local needle="$1"
  local file="$2"
  if ! grep -Fq "$needle" "$file"; then
    echo "Missing required text in $file: $needle" >&2
    exit 1
  fi
}

python3 -m json.tool "$ROOT/examples/replay-run.json" >/dev/null
python3 -m json.tool "$ROOT/examples/eval-run.json" >/dev/null
python3 -m json.tool "$ROOT/schemas/replay-run.schema.json" >/dev/null
python3 -m json.tool "$ROOT/schemas/eval-run.schema.json" >/dev/null
python3 "$ROOT/scripts/validate-examples.py" >/dev/null
python3 "$ROOT/scripts/validate-project-metadata.py" >/dev/null
python3 "$ROOT/scripts/validate-doc-links.py" >/dev/null
python3 "$ROOT/scripts/validate-markdown-fences.py" >/dev/null
python3 "$ROOT/scripts/validate-portability.py" >/dev/null
python3 "$ROOT/scripts/validate-script-hygiene.py" >/dev/null
python3 "$ROOT/scripts/validate-release-docs.py" >/dev/null
"$ROOT/scripts/verify-patch-manifest.sh" >/dev/null
"$ROOT/scripts/verify-reproducibility.sh" >/dev/null

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
  "$ROOT/docs/COMMANDS.md" \
  "$ROOT/docs/DEMO.md" \
  "$ROOT/docs/FAQ.md" \
  "$ROOT/docs/JSON_SCHEMA.md" \
  "$ROOT/docs/PRODUCT_BRIEF.md" \
  "$ROOT/docs/RELEASE.md" \
  "$ROOT/docs/REPRODUCIBILITY.md" \
  "$ROOT/docs/ROADMAP.md" \
  "$ROOT/docs/TESTING.md" \
  "$ROOT/docs/CEO_MESSAGE.md" \
  "$ROOT/patches/entire-replay-lab.patch" \
  "$ROOT/schemas/replay-run.schema.json" \
  "$ROOT/schemas/eval-run.schema.json" \
  "$ROOT/.github/workflows/ci.yml" \
  "$ROOT/scripts/check-all-agent-eval.sh" \
  "$ROOT/scripts/check-command-surface.sh" \
  "$ROOT/scripts/check-report-fixtures.sh" \
  "$ROOT/scripts/replay-lab-env.sh" \
  "$ROOT/scripts/validate-doc-links.py" \
  "$ROOT/scripts/validate-examples.py" \
  "$ROOT/scripts/validate-markdown-fences.py" \
  "$ROOT/scripts/validate-project-metadata.py" \
  "$ROOT/scripts/validate-portability.py" \
  "$ROOT/scripts/validate-release-docs.py" \
  "$ROOT/scripts/validate-script-hygiene.py" \
  "$ROOT/scripts/verify-patch-manifest.sh" \
  "$ROOT/scripts/verify-release-state.sh" \
  "$ROOT/scripts/verify-reproducibility.sh"
do
  require_file "$file"
done

require_contains "The Pain It Solves" "$ROOT/README.md"
require_contains "actions/workflows/ci.yml/badge.svg" "$ROOT/README.md"
require_contains "isolated worktree" "$ROOT/README.md"
require_contains "entire replay checkpoint" "$ROOT/docs/COMMANDS.md"
require_contains "One-Command Smoke" "$ROOT/docs/ACCEPTANCE.md"
require_contains "private benchmark" "$ROOT/docs/PRODUCT_BRIEF.md"
require_contains "Release Check" "$ROOT/docs/RELEASE.md"
require_contains "Pinned Inputs" "$ROOT/docs/REPRODUCIBILITY.md"
require_contains "Check all-agent eval fixture" "$ROOT/.github/workflows/ci.yml"
require_contains "all-agent eval command fixture" "$ROOT/scripts/check-all-agent-eval.sh"
require_contains "Replay/Eval command surface" "$ROOT/scripts/check-command-surface.sh"
require_contains "Replay/Eval report fixture" "$ROOT/scripts/check-report-fixtures.sh"
require_contains "Replay Lab Doctor" "$ROOT/scripts/doctor.sh"
require_contains "Release check" "$ROOT/scripts/release-check.sh"
require_contains "ENTIRE_CLI_DEFAULT_REF" "$ROOT/scripts/replay-lab-env.sh"
require_contains "ENTIRE_REPLAY_DEFAULT_PATCH_SHA256" "$ROOT/scripts/replay-lab-env.sh"
require_contains "Validate local Markdown links" "$ROOT/scripts/validate-doc-links.py"
require_contains "Validate Replay Lab example JSON" "$ROOT/scripts/validate-examples.py"
require_contains "Validate Markdown fenced code blocks" "$ROOT/scripts/validate-markdown-fences.py"
require_contains "Validate Replay Lab project metadata" "$ROOT/scripts/validate-project-metadata.py"
require_contains "Validate that reusable Replay Lab docs and scripts are machine-portable" "$ROOT/scripts/validate-portability.py"
require_contains "Validate Replay Lab helper script hygiene" "$ROOT/scripts/validate-script-hygiene.py"
require_contains "Validate changelog and release-note consistency" "$ROOT/scripts/validate-release-docs.py"
require_contains "Replay Lab patch manifest" "$ROOT/scripts/verify-patch-manifest.sh"
require_contains "GitHub releases match" "$ROOT/scripts/verify-release-state.sh"
require_contains "latest tag commit match" "$ROOT/scripts/verify-release-state.sh"
require_contains "release bodies" "$ROOT/scripts/verify-release-state.sh"
require_contains "Replay Lab reproducibility inputs" "$ROOT/scripts/verify-reproducibility.sh"
require_contains "schema_version" "$ROOT/docs/JSON_SCHEMA.md"
require_contains "cmd/entire/cli/replay.go" "$ROOT/patches/entire-replay-lab.patch"
require_contains "cmd/entire/cli/replay_test.go" "$ROOT/patches/entire-replay-lab.patch"
bash -n "$ROOT"/scripts/*.sh

echo "Replay Lab repo docs and examples look good."
