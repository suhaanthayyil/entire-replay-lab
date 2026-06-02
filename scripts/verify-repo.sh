#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 -m json.tool "$ROOT/examples/replay-run.json" >/dev/null
python3 -m json.tool "$ROOT/examples/eval-run.json" >/dev/null

for file in \
  "$ROOT/README.md" \
  "$ROOT/docs/ARCHITECTURE.md" \
  "$ROOT/docs/DEMO.md" \
  "$ROOT/docs/JSON_SCHEMA.md" \
  "$ROOT/docs/ROADMAP.md" \
  "$ROOT/docs/CEO_MESSAGE.md"
do
  test -s "$file"
done

grep -q "The Pain It Solves" "$ROOT/README.md"
grep -q "isolated worktree" "$ROOT/README.md"
grep -q "schema_version" "$ROOT/docs/JSON_SCHEMA.md"

echo "Replay Lab repo docs and examples look good."
