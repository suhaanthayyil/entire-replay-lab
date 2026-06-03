#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== Release check: repo verification =="
"$ROOT/scripts/verify-repo.sh"

echo
echo "== Release check: project metadata =="
python3 "$ROOT/scripts/validate-project-metadata.py"

echo
echo "== Release check: schema validation =="
python3 "$ROOT/scripts/validate-examples.py"

echo
echo "== Release check: markdown link validation =="
python3 "$ROOT/scripts/validate-doc-links.py"

echo
echo "== Release check: markdown fence validation =="
python3 "$ROOT/scripts/validate-markdown-fences.py"

echo
echo "== Release check: portability validation =="
python3 "$ROOT/scripts/validate-portability.py"

echo
echo "== Release check: script hygiene validation =="
python3 "$ROOT/scripts/validate-script-hygiene.py"

echo
echo "== Release check: release docs validation =="
python3 "$ROOT/scripts/validate-release-docs.py"

echo
echo "== Release check: reproducibility metadata =="
"$ROOT/scripts/verify-reproducibility.sh"

echo
echo "== Release check: patch manifest =="
"$ROOT/scripts/verify-patch-manifest.sh"

echo
echo "== Release check: patched CLI build =="
"$ROOT/scripts/build-cli.sh"

echo
echo "== Release check: build lock =="
"$ROOT/scripts/check-build-lock.sh"

echo
echo "== Release check: command surface =="
"$ROOT/scripts/check-command-surface.sh"

echo
echo "== Release check: report fixtures =="
"$ROOT/scripts/check-report-fixtures.sh"

echo
echo "== Release check: all-agent eval fixture =="
"$ROOT/scripts/check-all-agent-eval.sh"

echo
echo "== Release check: patch tests =="
"$ROOT/scripts/check-patch.sh"

echo
echo "Release check passed."
