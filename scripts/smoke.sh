#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_REPO="${1:-}"

echo "== Replay Lab smoke: repo verification =="
"$ROOT/scripts/verify-repo.sh"

echo
echo "== Replay Lab smoke: patched CLI build =="
"$ROOT/scripts/build-cli.sh"

echo
echo "== Replay Lab smoke: command surface =="
"$ROOT/bin/entire" replay --help >/dev/null
"$ROOT/bin/entire" replay checkpoint --help >/dev/null
"$ROOT/bin/entire" replay report --help >/dev/null
"$ROOT/bin/entire" eval --help >/dev/null
"$ROOT/bin/entire" eval run --help >/dev/null
"$ROOT/bin/entire" eval report --help >/dev/null
echo "Replay and eval commands are available."

echo
echo "== Replay Lab smoke: doctor =="
if [[ -n "$TARGET_REPO" ]]; then
  "$ROOT/scripts/doctor.sh" "$TARGET_REPO"
else
  "$ROOT/scripts/doctor.sh"
fi

echo
echo "== Replay Lab smoke: patch test =="
"$ROOT/scripts/check-patch.sh"

echo
echo "Replay Lab smoke passed."
