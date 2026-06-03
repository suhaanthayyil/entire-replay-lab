#!/usr/bin/env bash
# Shared Replay Lab build inputs. Source this after setting ROOT if available.

if [[ -z "${ROOT:-}" ]]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

ENTIRE_CLI_DEFAULT_REPO="https://github.com/entireio/cli.git"
ENTIRE_CLI_DEFAULT_REF="e858fb537e70b8008a10f712cb73588cb67aacf2"
ENTIRE_REPLAY_DEFAULT_PATCH="$ROOT/patches/entire-replay-lab.patch"
ENTIRE_REPLAY_DEFAULT_PATCH_SHA256="cbf6e2fde30be2562efa39570e960807190ebcd24b4d6003a8908f7d84bc6050"

: "${ENTIRE_CLI_REPO:=$ENTIRE_CLI_DEFAULT_REPO}"
: "${ENTIRE_CLI_REF:=$ENTIRE_CLI_DEFAULT_REF}"
: "${ENTIRE_REPLAY_PATCH:=$ENTIRE_REPLAY_DEFAULT_PATCH}"
: "${ENTIRE_REPLAY_PATCH_SHA256=$ENTIRE_REPLAY_DEFAULT_PATCH_SHA256}"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'ENTIRE_CLI_REPO=%s\n' "$ENTIRE_CLI_REPO"
  printf 'ENTIRE_CLI_REF=%s\n' "$ENTIRE_CLI_REF"
  printf 'ENTIRE_REPLAY_PATCH=%s\n' "$ENTIRE_REPLAY_PATCH"
  printf 'ENTIRE_REPLAY_PATCH_SHA256=%s\n' "$ENTIRE_REPLAY_PATCH_SHA256"
fi
