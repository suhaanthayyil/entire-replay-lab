#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_REPO="${1:-}"
ENTIRE_BIN="${ENTIRE_BIN:-$ROOT/bin/entire}"
CHECKPOINT_OUTPUT=""

cleanup() {
  if [[ -n "$CHECKPOINT_OUTPUT" ]]; then
    rm -f "$CHECKPOINT_OUTPUT"
  fi
}
trap cleanup EXIT

failures=0
warnings=0

ok() {
  printf 'OK    %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf 'WARN  %s\n' "$1"
}

info() {
  printf 'INFO  %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL  %s\n' "$1"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

required_cmd() {
  if has_cmd "$1"; then
    ok "$1 found: $(command -v "$1")"
  else
    fail "$1 is required"
  fi
}

optional_cmd() {
  if has_cmd "$1"; then
    ok "$1 found: $(command -v "$1")"
  else
    warn "$1 not found: $2"
  fi
}

echo "Replay Lab Doctor"
echo

required_cmd git
required_cmd go
required_cmd python3

optional_cmd claude "Claude Code replays will be unavailable"
optional_cmd codex "Codex replays will be unavailable"
optional_cmd gemini "Gemini CLI replays will be unavailable"
optional_cmd entire-sem "semantic similarity will be unavailable"
info "native replay launchers: claude-code, codex, gemini"
info "eval --agent all also reports copilot-cli, cursor, factoryai-droid, opencode, and pi as skipped until launchers exist"

if [[ -x "$ENTIRE_BIN" ]]; then
  ok "Replay Lab binary found: $ENTIRE_BIN"
  if "$ENTIRE_BIN" replay --help >/dev/null 2>&1; then
    ok "entire replay command is available"
  else
    fail "entire replay command is missing from $ENTIRE_BIN"
  fi
  if "$ENTIRE_BIN" eval --help >/dev/null 2>&1; then
    ok "entire eval command is available"
  else
    fail "entire eval command is missing from $ENTIRE_BIN"
  fi
else
  warn "Replay Lab binary not built yet; run ./scripts/build-cli.sh"
fi

if [[ -n "$TARGET_REPO" ]]; then
  echo
  echo "Target repo: $TARGET_REPO"
  if [[ ! -d "$TARGET_REPO" ]]; then
    fail "target repo path does not exist"
  elif ! git -C "$TARGET_REPO" rev-parse --show-toplevel >/dev/null 2>&1; then
    fail "target repo is not a git repository"
  else
    repo_root="$(git -C "$TARGET_REPO" rev-parse --show-toplevel)"
    ok "git repo found: $repo_root"
    if [[ -f "$repo_root/.entire/settings.json" ]]; then
      ok "Entire settings found"
    else
      warn "Entire settings not found; run entire enable before expecting checkpoints"
    fi
    if [[ -x "$ENTIRE_BIN" ]]; then
      CHECKPOINT_OUTPUT="$(mktemp "${TMPDIR:-/tmp}/entire-replay-doctor-checkpoints.XXXXXX")"
      if (cd "$repo_root" && "$ENTIRE_BIN" checkpoint list >"$CHECKPOINT_OUTPUT" 2>&1); then
        if grep -q "checkpoints  0" "$CHECKPOINT_OUTPUT"; then
          warn "checkpoint list works but found zero checkpoints"
        else
          ok "checkpoint list works"
        fi
      else
        warn "checkpoint list failed; inspect target repo setup"
      fi
    fi
  fi
fi

echo
printf 'Doctor finished with %d failure(s), %d warning(s).\n' "$failures" "$warnings"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
