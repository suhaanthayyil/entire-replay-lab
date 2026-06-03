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

echo "OK Replay/Eval command surface is available in $ENTIRE_BIN."
