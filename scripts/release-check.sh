#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== Release check: repo verification =="
"$ROOT/scripts/verify-repo.sh"

echo
echo "== Release check: schema validation =="
python3 "$ROOT/scripts/validate-examples.py"

echo
echo "== Release check: patched CLI build =="
"$ROOT/scripts/build-cli.sh"

echo
echo "== Release check: command surface =="
"$ROOT/bin/entire" replay --help >/dev/null
"$ROOT/bin/entire" replay checkpoint --help >/dev/null
"$ROOT/bin/entire" replay report --help >/dev/null
"$ROOT/bin/entire" eval --help >/dev/null
"$ROOT/bin/entire" eval run --help >/dev/null
"$ROOT/bin/entire" eval report --help >/dev/null
echo "Replay and eval commands are available."

echo
echo "== Release check: patch tests =="
"$ROOT/scripts/check-patch.sh"

echo
echo "Release check passed."
