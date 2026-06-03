#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/replay-lab-env.sh"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/entire-replay-patch-manifest.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

NUMSTAT="$WORKDIR/numstat.txt"
SUMMARY="$WORKDIR/summary.txt"

git apply --numstat "$ENTIRE_REPLAY_PATCH" >"$NUMSTAT"
git apply --summary "$ENTIRE_REPLAY_PATCH" >"$SUMMARY"

python3 - "$NUMSTAT" "$SUMMARY" <<'PY'
import sys
from pathlib import Path

numstat = Path(sys.argv[1])
summary = Path(sys.argv[2])

expected = {
    "README.md",
    "cmd/entire/cli/root.go",
    "cmd/entire/cli/replay.go",
    "cmd/entire/cli/replay_test.go",
}
created = {
    "cmd/entire/cli/replay.go",
    "cmd/entire/cli/replay_test.go",
}
errors = []
paths = set()

for line in numstat.read_text(encoding="utf-8").splitlines():
    parts = line.split("\t")
    if len(parts) != 3:
        errors.append(f"invalid numstat line: {line}")
        continue
    added, deleted, path = parts
    paths.add(path)
    if added == "-" or deleted == "-":
        errors.append(f"binary patch is not expected: {path}")
        continue
    if int(deleted) != 0:
        errors.append(f"patch should not delete lines in {path}: {deleted}")
    if int(added) <= 0:
        errors.append(f"patch should add lines in {path}")

if paths != expected:
    errors.append(
        "patch file set mismatch: "
        f"expected {', '.join(sorted(expected))}; got {', '.join(sorted(paths))}"
    )

summary_text = summary.read_text(encoding="utf-8")
for path in created:
    if f"create mode 100644 {path}" not in summary_text:
        errors.append(f"patch should create {path}")

for path in expected - created:
    if f"create mode 100644 {path}" in summary_text:
        errors.append(f"patch should modify, not create, {path}")

if errors:
    print("Patch manifest validation failed:", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    raise SystemExit(1)
PY

for needle in \
  "func newReplayCmd" \
  "func newEvalCmd" \
  "replayAgentAll" \
  "TestReplayEvalAllAgentsExpandsEntireCoderList" \
  "one failed row per selected agent" \
  "TestReplayAgentAliasesCanonicalize" \
  "TestRootCommandHasReplayAndEval" \
  "TestRunReplayProcessPreservesTimeoutErrorAndOutput" \
  "TestRunReplayTestCommandPreservesTimeoutErrorAndOutput" \
  "TestReplayCheckpointReportsWorktreePathWhenCleanupFails" \
  "TestReplayCheckpointTimeoutBudgetAppliesSeparatelyToAgentAndTest" \
  "TestReplayCheckpointWarnsWhenInstalledSemanticScoringFails"
do
  if ! grep -Fq "$needle" "$ENTIRE_REPLAY_PATCH"; then
    echo "Patch missing required text: $needle" >&2
    exit 1
  fi
done

echo "OK Replay Lab patch manifest matches expected files and test anchors."
