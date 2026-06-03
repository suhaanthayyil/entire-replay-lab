#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTIRE_BIN="${ENTIRE_BIN:-$ROOT/bin/entire}"

if [[ ! -x "$ENTIRE_BIN" ]]; then
  echo "Replay Lab binary is not executable: $ENTIRE_BIN" >&2
  echo "Run ./scripts/build-cli.sh first, or set ENTIRE_BIN=/path/to/entire." >&2
  exit 1
fi

check_help() {
  "$ENTIRE_BIN" "$@" --help >/dev/null
}

check_help replay
check_help replay checkpoint
check_help replay report
check_help eval
check_help eval run
check_help eval report

"$ENTIRE_BIN" replay --help | grep -Fq "checkpoint"
"$ENTIRE_BIN" replay --help | grep -Fq "report"
"$ENTIRE_BIN" eval --help | grep -Fq "run"
"$ENTIRE_BIN" eval --help | grep -Fq "report"

echo "OK Replay/Eval command surface is available in $ENTIRE_BIN."
