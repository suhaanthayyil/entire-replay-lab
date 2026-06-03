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

PATCH_PATHS=(
  README.md \
  cmd/entire/cli/replay.go \
  cmd/entire/cli/replay_test.go \
  cmd/entire/cli/root.go
)

INDEX_FILE="$(git -C "$ENTIRE_CLI_SOURCE" rev-parse --git-path index)"
TMP_INDEX="$(mktemp "${TMPDIR:-/tmp}/entire-replay-refresh-index.XXXXXX")"
cp "$INDEX_FILE" "$TMP_INDEX"
cleanup() {
  rm -f "$TMP_INDEX"
}
trap cleanup EXIT

for path in "${PATCH_PATHS[@]}"; do
  if [[ -e "$ENTIRE_CLI_SOURCE/$path" ]]; then
    GIT_INDEX_FILE="$TMP_INDEX" git -C "$ENTIRE_CLI_SOURCE" add --intent-to-add -- "$path"
  fi
done

GIT_INDEX_FILE="$TMP_INDEX" git -C "$ENTIRE_CLI_SOURCE" diff --binary "$ENTIRE_CLI_BASE" -- \
  "${PATCH_PATHS[@]}" >"$ENTIRE_REPLAY_PATCH"

test -s "$ENTIRE_REPLAY_PATCH"
echo "Wrote $ENTIRE_REPLAY_PATCH"
