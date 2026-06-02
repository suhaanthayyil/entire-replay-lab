#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

rm -rf "$ROOT/bin" "$ROOT/tmp"
echo "Removed generated Replay Lab build artifacts."
