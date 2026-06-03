#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_SLUG="${GITHUB_REPOSITORY:-suhaanthayyil/entire-replay-lab}"
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/entire-replay-release-state.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

DOC_FILE="$WORKDIR/docs.txt"
TAG_FILE="$WORKDIR/tags.txt"
GH_FILE="$WORKDIR/github.txt"
RAW_TAG_FILE="$WORKDIR/raw-tags.txt"
RAW_GH_FILE="$WORKDIR/raw-github.txt"

python3 - "$ROOT" >"$DOC_FILE" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
versions = set()
for path in sorted((root / "docs" / "releases").glob("v*.md")):
    if re.fullmatch(r"v\d+\.\d+\.\d+", path.stem):
        versions.add(path.stem)

def semver(version):
    return tuple(int(part) for part in version.removeprefix("v").split("."))

print("\n".join(sorted(versions, key=semver)))
PY

git -C "$ROOT" tag --list 'v[0-9]*.[0-9]*.[0-9]*' >"$RAW_TAG_FILE"
python3 - "$RAW_TAG_FILE" >"$TAG_FILE" <<'PY'
import re
import sys
from pathlib import Path

versions = {
    line.strip()
    for line in Path(sys.argv[1]).read_text().splitlines()
    if re.fullmatch(r"v\d+\.\d+\.\d+", line.strip())
}

def semver(version):
    return tuple(int(part) for part in version.removeprefix("v").split("."))

print("\n".join(sorted(versions, key=semver)))
PY

if ! cmp -s "$DOC_FILE" "$TAG_FILE"; then
  echo "Release docs and local git tags differ." >&2
  echo "docs/releases:" >&2
  sed 's/^/  /' "$DOC_FILE" >&2
  echo "git tags:" >&2
  sed 's/^/  /' "$TAG_FILE" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "OK release docs match local git tags. GitHub release check skipped: gh not found."
  exit 0
fi

gh release list --repo "$REPO_SLUG" --limit 200 --json tagName,isDraft,isPrerelease --jq '.[] | select(.isDraft == false and .isPrerelease == false) | .tagName' >"$RAW_GH_FILE"
python3 - "$RAW_GH_FILE" >"$GH_FILE" <<'PY'
import re
import sys
from pathlib import Path

versions = {
    line.strip()
    for line in Path(sys.argv[1]).read_text().splitlines()
    if re.fullmatch(r"v\d+\.\d+\.\d+", line.strip())
}

def semver(version):
    return tuple(int(part) for part in version.removeprefix("v").split("."))

print("\n".join(sorted(versions, key=semver)))
PY

if ! cmp -s "$DOC_FILE" "$GH_FILE"; then
  echo "Release docs and published GitHub releases differ." >&2
  echo "docs/releases:" >&2
  sed 's/^/  /' "$DOC_FILE" >&2
  echo "github:" >&2
  sed 's/^/  /' "$GH_FILE" >&2
  exit 1
fi

LATEST_DOC="$(tail -n 1 "$DOC_FILE")"
LATEST_GH="$(gh release list --repo "$REPO_SLUG" --limit 1 --json tagName --jq '.[0].tagName')"
if [[ "$LATEST_DOC" != "$LATEST_GH" ]]; then
  echo "Latest GitHub release should be $LATEST_DOC, got $LATEST_GH." >&2
  exit 1
fi

echo "OK release docs, local tags, and GitHub releases match; latest $LATEST_DOC."
