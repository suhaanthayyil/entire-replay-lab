#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTIRE_BIN="${ENTIRE_BIN:-$ROOT/bin/entire}"

if [[ ! -x "$ENTIRE_BIN" ]]; then
  echo "Replay Lab binary is not executable: $ENTIRE_BIN" >&2
  echo "Run ./scripts/build-cli.sh first, or set ENTIRE_BIN=/path/to/entire." >&2
  exit 1
fi

check_help() {
  "$ENTIRE_BIN" "$@" --help >/dev/null
}

require_help_contains() {
  local description="$1"
  shift
  local needle="$1"
  shift
  local help_output

  help_output="$("$ENTIRE_BIN" "$@" --help)"
  if ! grep -Fq -- "$needle" <<<"$help_output"; then
    echo "Missing $description in '$ENTIRE_BIN $* --help': $needle" >&2
    exit 1
  fi
}

require_command_fails_contains() {
  local description="$1"
  shift
  local needle="$1"
  shift
  local output

  if output="$("$ENTIRE_BIN" "$@" 2>&1)"; then
    echo "Expected '$ENTIRE_BIN $*' to fail for $description" >&2
    exit 1
  fi
  if ! grep -Fq -- "$needle" <<<"$output"; then
    echo "Missing $description in failing '$ENTIRE_BIN $*' output: $needle" >&2
    echo "$output" >&2
    exit 1
  fi
}

check_help replay
check_help replay checkpoint
check_help replay report
check_help eval
check_help eval run
check_help eval report

require_help_contains "replay checkpoint subcommand" "checkpoint" replay
require_help_contains "replay report subcommand" "report" replay
require_help_contains "eval run subcommand" "run" eval
require_help_contains "eval report subcommand" "report" eval

for flag in --agent --model --test-cmd --keep-worktree --json --timeout; do
  require_help_contains "replay checkpoint flag" "$flag" replay checkpoint
done

require_help_contains "replay report json flag" "--json" replay report

for flag in --checkpoint --from-checkpoints --limit --agent --model --test-cmd --keep-worktree --json --timeout; do
  require_help_contains "eval run flag" "$flag" eval run
done

require_help_contains "replay checkpoint launchable agents" "Agent to replay with: claude-code, codex, copilot-cli, cursor, factoryai-droid, gemini, opencode" replay checkpoint
require_help_contains "eval run all-agent shortcut" "use all for every built-in Entire coder" eval run
require_help_contains "eval report json flag" "--json" eval report

require_command_fails_contains "replay checkpoint rejecting --agent all" \
  "agent \"all\" is only supported for eval runs" \
  replay checkpoint deadbeef --agent all
require_command_fails_contains "replay checkpoint rejecting unknown agents" \
  "unknown replay agent \"unknown-agent\"" \
  replay checkpoint deadbeef --agent unknown-agent
require_command_fails_contains "eval run rejecting non-positive checkpoint limit" \
  "--limit must be positive when using --from-checkpoints" \
  eval run --from-checkpoints --limit 0

echo "OK Replay/Eval command surface is available in $ENTIRE_BIN."
