#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/replay-lab-env.sh"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/entire-replay-refresh-check.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

git clone --quiet "$ENTIRE_CLI_REPO" "$WORKDIR/cli"
if git -C "$WORKDIR/cli" rev-parse --verify --quiet "$ENTIRE_CLI_REF^{commit}" >/dev/null; then
  CHECKOUT_REF="$ENTIRE_CLI_REF"
else
  git -C "$WORKDIR/cli" fetch --quiet origin "$ENTIRE_CLI_REF"
  CHECKOUT_REF="FETCH_HEAD"
fi
git -C "$WORKDIR/cli" checkout --quiet --detach "$CHECKOUT_REF"
git -C "$WORKDIR/cli" apply "$ENTIRE_REPLAY_PATCH"

git -C "$WORKDIR/cli" status --porcelain=v1 >"$WORKDIR/status.before"
for expected in \
  " M README.md" \
  " M cmd/entire/cli/root.go" \
  "?? cmd/entire/cli/replay.go" \
  "?? cmd/entire/cli/replay_test.go"
do
  if ! grep -Fxq "$expected" "$WORKDIR/status.before"; then
    echo "Patched checkout missing expected dirty state: $expected" >&2
    cat "$WORKDIR/status.before" >&2
    exit 1
  fi
done

ENTIRE_CLI_SOURCE="$WORKDIR/cli" \
  ENTIRE_REPLAY_PATCH="$WORKDIR/refreshed.patch" \
  "$ROOT/scripts/refresh-patch.sh" >/dev/null

git -C "$WORKDIR/cli" status --porcelain=v1 >"$WORKDIR/status.after"
if ! cmp -s "$WORKDIR/status.before" "$WORKDIR/status.after"; then
  echo "refresh-patch.sh changed the source checkout git status." >&2
  diff -u "$WORKDIR/status.before" "$WORKDIR/status.after" >&2 || true
  exit 1
fi

if ! cmp -s "$ENTIRE_REPLAY_PATCH" "$WORKDIR/refreshed.patch"; then
  echo "refresh-patch.sh did not reproduce the checked-in patch." >&2
  git diff --no-index --stat "$ENTIRE_REPLAY_PATCH" "$WORKDIR/refreshed.patch" >&2 || true
  exit 1
fi

echo "OK patch refresh reproduces the checked-in patch without mutating the source index."
