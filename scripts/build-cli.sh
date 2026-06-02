#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/bin/entire"

: "${ENTIRE_CLI_SOURCE:=/Users/suhaan/Documents/Coding/cli-replay-lab}"
: "${ENTIRE_CLI_REF:=codex/entire-replay-lab}"

mkdir -p "$ROOT/bin" "$ROOT/tmp"

if [[ -d "$ENTIRE_CLI_SOURCE/.git" || -f "$ENTIRE_CLI_SOURCE/.git" ]]; then
  CLI_DIR="$ENTIRE_CLI_SOURCE"
else
  CLI_DIR="$ROOT/tmp/cli"
  if [[ ! -d "$CLI_DIR/.git" ]]; then
    git clone --branch "$ENTIRE_CLI_REF" "$ENTIRE_CLI_SOURCE" "$CLI_DIR"
  else
    git -C "$CLI_DIR" fetch origin "$ENTIRE_CLI_REF"
    git -C "$CLI_DIR" checkout "$ENTIRE_CLI_REF"
    git -C "$CLI_DIR" pull --ff-only
  fi
fi

echo "Building Entire CLI from: $CLI_DIR"
git -C "$CLI_DIR" status --short --branch
go build -C "$CLI_DIR" -o "$OUT" ./cmd/entire

echo "Built: $OUT"
"$OUT" version || true
