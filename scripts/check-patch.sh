#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/replay-lab-env.sh"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/entire-replay-patch-check.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

git clone --quiet "$ENTIRE_CLI_REPO" "$WORKDIR/cli"
if git -C "$WORKDIR/cli" rev-parse --verify --quiet "$ENTIRE_CLI_REF^{commit}" >/dev/null; then
  CHECKOUT_REF="$ENTIRE_CLI_REF"
else
  git -C "$WORKDIR/cli" fetch --quiet origin "$ENTIRE_CLI_REF"
  CHECKOUT_REF="FETCH_HEAD"
fi
git -C "$WORKDIR/cli" checkout --quiet --detach "$CHECKOUT_REF"
git -C "$WORKDIR/cli" apply --check "$ENTIRE_REPLAY_PATCH"
git -C "$WORKDIR/cli" apply "$ENTIRE_REPLAY_PATCH"

go test -C "$WORKDIR/cli" ./cmd/entire/cli -run 'TestReplay|TestBuildReplay|TestCommitReplay|TestExtractReplay|TestRootCommandHasReplayAndEval|TestSortReplay|TestRenderReplayRun|TestRunReplayProcess' -count=1

echo "Replay Lab patch applies cleanly and replay tests pass."
