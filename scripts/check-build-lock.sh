#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_DIR="$ROOT/tmp/build-cli.lock"
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/entire-replay-build-lock.XXXXXX")"

cleanup() {
  rm -rf "$WORKDIR"
  if [[ -f "$LOCK_DIR/pid" ]]; then
    LOCK_PID="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
    if [[ "$LOCK_PID" == "stale-test-pid" || "$LOCK_PID" == "$$" ]]; then
      rm -rf "$LOCK_DIR"
    fi
  fi
}
trap cleanup EXIT

rm -rf "$LOCK_DIR"

BUILD_TIMEOUT="${ENTIRE_BUILD_LOCK_TIMEOUT:-300}"
LOG_A="$WORKDIR/build-a.log"
LOG_B="$WORKDIR/build-b.log"
LOG_STALE="$WORKDIR/build-stale.log"
LOG_TIMEOUT="$WORKDIR/build-timeout.log"

require_replay_binary() {
  if [[ ! -x "$ROOT/bin/entire" ]]; then
    echo "Replay Lab binary missing after build-lock check: $ROOT/bin/entire" >&2
    exit 1
  fi

  "$ROOT/bin/entire" replay --help >/dev/null
  "$ROOT/bin/entire" eval --help >/dev/null
}

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

require_replay_binary

mkdir -p "$LOCK_DIR"
printf '%s\n' "stale-test-pid" >"$LOCK_DIR/pid"
ENTIRE_BUILD_LOCK_TIMEOUT="$BUILD_TIMEOUT" "$ROOT/scripts/build-cli.sh" >"$LOG_STALE" 2>&1

if [[ -d "$LOCK_DIR" ]]; then
  echo "Stale build lock was not cleaned up: $LOCK_DIR" >&2
  cat "$LOG_STALE" >&2 || true
  exit 1
fi

require_replay_binary

mkdir -p "$LOCK_DIR"
printf '%s\n' "$$" >"$LOCK_DIR/pid"
set +e
ENTIRE_BUILD_LOCK_TIMEOUT=1 "$ROOT/scripts/build-cli.sh" >"$LOG_TIMEOUT" 2>&1
TIMEOUT_STATUS=$?
set -e

if [[ "$TIMEOUT_STATUS" == "0" ]]; then
  echo "Build unexpectedly succeeded while an active lock was held." >&2
  cat "$LOG_TIMEOUT" >&2 || true
  exit 1
fi

if ! grep -Fq "Timed out waiting for Replay Lab build lock" "$LOG_TIMEOUT"; then
  echo "Build lock timeout did not emit the expected error." >&2
  cat "$LOG_TIMEOUT" >&2 || true
  exit 1
fi

if [[ ! -d "$LOCK_DIR" ]]; then
  echo "Held build lock disappeared during timeout check." >&2
  exit 1
fi
rm -rf "$LOCK_DIR"

echo "OK Replay Lab build lock handles concurrent builds, stale locks, and active-lock timeouts."
