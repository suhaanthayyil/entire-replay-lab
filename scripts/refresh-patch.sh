#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/replay-lab-env.sh"

: "${ENTIRE_CLI_BASE:=$ENTIRE_CLI_REF}"

if [[ -z "${ENTIRE_CLI_SOURCE:-}" ]]; then
  echo "Set ENTIRE_CLI_SOURCE=/path/to/cli-replay-lab before refreshing the patch." >&2
  exit 1
fi

if [[ ! -d "$ENTIRE_CLI_SOURCE/.git" && ! -f "$ENTIRE_CLI_SOURCE/.git" ]]; then
  echo "ENTIRE_CLI_SOURCE is not a git checkout: $ENTIRE_CLI_SOURCE" >&2
  exit 1
fi

mkdir -p "$(dirname "$ENTIRE_REPLAY_PATCH")"

git -C "$ENTIRE_CLI_SOURCE" diff --binary "$ENTIRE_CLI_BASE"...HEAD -- \
  README.md \
  cmd/entire/cli/replay.go \
  cmd/entire/cli/replay_test.go \
  cmd/entire/cli/root.go \
  > "$ENTIRE_REPLAY_PATCH"

test -s "$ENTIRE_REPLAY_PATCH"
echo "Wrote $ENTIRE_REPLAY_PATCH"
