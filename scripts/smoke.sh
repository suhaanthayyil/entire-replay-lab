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
echo "== Replay Lab smoke: patch refresh =="
"$ROOT/scripts/check-refresh-patch.sh"

echo
echo "== Replay Lab smoke: build lock =="
"$ROOT/scripts/check-build-lock.sh"

echo
echo "== Replay Lab smoke: command surface =="
"$ROOT/scripts/check-command-surface.sh"

echo
echo "== Replay Lab smoke: report fixtures =="
"$ROOT/scripts/check-report-fixtures.sh"

echo
echo "== Replay Lab smoke: all-agent eval fixture =="
"$ROOT/scripts/check-all-agent-eval.sh"

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
