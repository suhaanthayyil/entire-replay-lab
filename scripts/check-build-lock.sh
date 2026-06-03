#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_DIR="$ROOT/tmp/build-cli.lock"
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/entire-replay-build-lock.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

rm -rf "$LOCK_DIR"

BUILD_TIMEOUT="${ENTIRE_BUILD_LOCK_TIMEOUT:-300}"
LOG_A="$WORKDIR/build-a.log"
LOG_B="$WORKDIR/build-b.log"

ENTIRE_BUILD_LOCK_TIMEOUT="$BUILD_TIMEOUT" "$ROOT/scripts/build-cli.sh" >"$LOG_A" 2>&1 &
PID_A=$!

LOCK_SEEN=0
for _ in {1..120}; do
  if [[ -d "$LOCK_DIR" ]]; then
    LOCK_SEEN=1
    break
  fi
  sleep 0.25
done

if [[ "$LOCK_SEEN" != "1" ]]; then
  echo "First build did not acquire the build lock." >&2
  cat "$LOG_A" >&2 || true
  wait "$PID_A" || true
  exit 1
fi

ENTIRE_BUILD_LOCK_TIMEOUT="$BUILD_TIMEOUT" "$ROOT/scripts/build-cli.sh" >"$LOG_B" 2>&1 &
PID_B=$!

if ! wait "$PID_A"; then
  echo "First concurrent build failed:" >&2
  cat "$LOG_A" >&2 || true
  wait "$PID_B" || true
  exit 1
fi

if ! wait "$PID_B"; then
  echo "Second concurrent build failed:" >&2
  cat "$LOG_B" >&2 || true
  exit 1
fi

if [[ -d "$LOCK_DIR" ]]; then
  echo "Build lock was not cleaned up: $LOCK_DIR" >&2
  exit 1
fi

if [[ ! -x "$ROOT/bin/entire" ]]; then
  echo "Replay Lab binary missing after concurrent builds: $ROOT/bin/entire" >&2
  exit 1
fi

"$ROOT/bin/entire" replay --help >/dev/null
"$ROOT/bin/entire" eval --help >/dev/null

echo "OK Replay Lab build lock allows concurrent build-cli invocations safely."
