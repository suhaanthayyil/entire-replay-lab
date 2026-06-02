#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/bin/entire"

: "${ENTIRE_CLI_REPO:=https://github.com/entireio/cli.git}"
: "${ENTIRE_CLI_REF:=e858fb537e70b8008a10f712cb73588cb67aacf2}"
: "${ENTIRE_REPLAY_PATCH:=$ROOT/patches/entire-replay-lab.patch}"

mkdir -p "$ROOT/bin" "$ROOT/tmp"

if [[ -n "${ENTIRE_CLI_SOURCE:-}" && ( -d "$ENTIRE_CLI_SOURCE/.git" || -f "$ENTIRE_CLI_SOURCE/.git" ) ]]; then
  CLI_DIR="$ENTIRE_CLI_SOURCE"
else
  CLI_DIR="$ROOT/tmp/cli"
  if [[ ! -d "$CLI_DIR/.git" && ! -f "$CLI_DIR/.git" ]]; then
    git clone "$ENTIRE_CLI_REPO" "$CLI_DIR"
  else
    git -C "$CLI_DIR" fetch origin --tags
  fi
  git -C "$CLI_DIR" checkout --detach "$ENTIRE_CLI_REF"
  git -C "$CLI_DIR" reset --hard "$ENTIRE_CLI_REF" >/dev/null
  if [[ -f "$ENTIRE_REPLAY_PATCH" ]]; then
    git -C "$CLI_DIR" apply --check "$ENTIRE_REPLAY_PATCH"
    git -C "$CLI_DIR" apply "$ENTIRE_REPLAY_PATCH"
  fi
fi

echo "Building Entire CLI from: $CLI_DIR"
git -C "$CLI_DIR" status --short --branch
go build -C "$CLI_DIR" -o "$OUT" ./cmd/entire

echo "Built: $OUT"
"$OUT" version || true
