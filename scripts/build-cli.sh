#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/replay-lab-env.sh"
OUT="$ROOT/bin/entire"

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
  if git -C "$CLI_DIR" rev-parse --verify --quiet "$ENTIRE_CLI_REF^{commit}" >/dev/null; then
    CHECKOUT_REF="$ENTIRE_CLI_REF"
  else
    git -C "$CLI_DIR" fetch origin "$ENTIRE_CLI_REF"
    CHECKOUT_REF="FETCH_HEAD"
  fi
  git -C "$CLI_DIR" checkout --detach "$CHECKOUT_REF"
  git -C "$CLI_DIR" reset --hard "$CHECKOUT_REF" >/dev/null
  git -C "$CLI_DIR" clean -fd >/dev/null
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
