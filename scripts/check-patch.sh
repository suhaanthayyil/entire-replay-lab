#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${ENTIRE_CLI_REPO:=https://github.com/entireio/cli.git}"
: "${ENTIRE_CLI_REF:=e858fb537e70b8008a10f712cb73588cb67aacf2}"
: "${ENTIRE_REPLAY_PATCH:=$ROOT/patches/entire-replay-lab.patch}"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/entire-replay-patch-check.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

git clone --quiet "$ENTIRE_CLI_REPO" "$WORKDIR/cli"
git -C "$WORKDIR/cli" checkout --quiet --detach "$ENTIRE_CLI_REF"
git -C "$WORKDIR/cli" apply --check "$ENTIRE_REPLAY_PATCH"
git -C "$WORKDIR/cli" apply "$ENTIRE_REPLAY_PATCH"

go test -C "$WORKDIR/cli" ./cmd/entire/cli -run 'TestReplay|TestBuildReplay|TestCommitReplay|TestExtractReplay|TestRootCommandHasReplayAndEval|TestSortReplay|TestRenderReplayRun|TestRunReplayProcess' -count=1

echo "Replay Lab patch applies cleanly and replay tests pass."
