#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/replay-lab-env.sh"

require_contains() {
  local needle="$1"
  local file="$2"
  if ! grep -Fq "$needle" "$file"; then
    echo "Missing required text in $file: $needle" >&2
    exit 1
  fi
}

require_sourced_env() {
  local file="$1"
  require_contains 'source "$ROOT/scripts/replay-lab-env.sh"' "$file"
}

if [[ -z "$ENTIRE_CLI_REPO" || -z "$ENTIRE_CLI_REF" || -z "$ENTIRE_REPLAY_PATCH" ]]; then
  echo "Replay Lab build inputs must be non-empty." >&2
  exit 1
fi

if [[ ! -f "$ENTIRE_REPLAY_PATCH" ]]; then
  echo "Replay Lab patch not found: $ENTIRE_REPLAY_PATCH" >&2
  exit 1
fi

if [[ "$ENTIRE_CLI_REF" == "$ENTIRE_CLI_DEFAULT_REF" && ! "$ENTIRE_CLI_REF" =~ ^[0-9a-f]{40,64}$ ]]; then
  echo "Default ENTIRE_CLI_REF should be a full commit hash: $ENTIRE_CLI_REF" >&2
  exit 1
fi

require_sourced_env "$ROOT/scripts/build-cli.sh"
require_sourced_env "$ROOT/scripts/check-patch.sh"
require_sourced_env "$ROOT/scripts/refresh-patch.sh"

require_contains "$ENTIRE_CLI_DEFAULT_REPO" "$ROOT/README.md"
require_contains "$ENTIRE_CLI_DEFAULT_REF" "$ROOT/README.md"
require_contains "$ENTIRE_CLI_DEFAULT_REF" "$ROOT/docs/ARCHITECTURE.md"
require_contains "$ENTIRE_CLI_DEFAULT_REF" "$ROOT/docs/TESTING.md"
require_contains "$ENTIRE_CLI_DEFAULT_REF" "$ROOT/docs/REPRODUCIBILITY.md"
require_contains "ENTIRE_CLI_DEFAULT_REF" "$ROOT/scripts/replay-lab-env.sh"
require_contains "ENTIRE_REPLAY_DEFAULT_PATCH_SHA256" "$ROOT/scripts/replay-lab-env.sh"
require_contains "$ENTIRE_REPLAY_DEFAULT_PATCH_SHA256" "$ROOT/docs/REPRODUCIBILITY.md"

if command -v shasum >/dev/null 2>&1; then
  PATCH_SHA="$(shasum -a 256 "$ENTIRE_REPLAY_PATCH" | awk '{print $1}')"
elif command -v sha256sum >/dev/null 2>&1; then
  PATCH_SHA="$(sha256sum "$ENTIRE_REPLAY_PATCH" | awk '{print $1}')"
else
  PATCH_SHA="unavailable"
fi

if [[ -n "${ENTIRE_REPLAY_PATCH_SHA256:-}" ]]; then
  if [[ "$PATCH_SHA" == "unavailable" ]]; then
    echo "Cannot verify Replay Lab patch hash: no SHA-256 tool found." >&2
    exit 1
  fi
  if [[ "$PATCH_SHA" != "$ENTIRE_REPLAY_PATCH_SHA256" ]]; then
    echo "Replay Lab patch SHA-256 mismatch." >&2
    echo "  expected: $ENTIRE_REPLAY_PATCH_SHA256" >&2
    echo "  actual:   $PATCH_SHA" >&2
    echo "If this is an intentional local experiment, set ENTIRE_REPLAY_PATCH_SHA256= to disable the hash pin." >&2
    exit 1
  fi
fi

echo "Replay Lab reproducibility inputs:"
echo "  repo:  $ENTIRE_CLI_REPO"
echo "  ref:   $ENTIRE_CLI_REF"
echo "  patch: $ENTIRE_REPLAY_PATCH"
echo "  sha256: $PATCH_SHA"
echo "  expected_sha256: ${ENTIRE_REPLAY_PATCH_SHA256:-unverified}"
