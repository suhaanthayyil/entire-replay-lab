#!/usr/bin/env python3
"""Validate changelog and release-note consistency."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHANGELOG = ROOT / "CHANGELOG.md"
RELEASE_DIR = ROOT / "docs" / "releases"

VERSION_RE = re.compile(r"^v\d+\.\d+\.\d+$")
CHANGELOG_HEADING_RE = re.compile(r"^## (v\d+\.\d+\.\d+) - \d{4}-\d{2}-\d{2}$")


def changelog_versions() -> list[str]:
    versions: list[str] = []
    for line in CHANGELOG.read_text(encoding="utf-8").splitlines():
        match = CHANGELOG_HEADING_RE.match(line)
        if match:
            versions.append(match.group(1))
    return versions


def semver_key(version: str) -> tuple[int, int, int]:
    major, minor, patch = version.removeprefix("v").split(".")
    return int(major), int(minor), int(patch)


def release_note_versions() -> list[str]:
    versions: list[str] = []
    for path in sorted(RELEASE_DIR.glob("v*.md")):
        version = path.stem
        if VERSION_RE.fullmatch(version):
            versions.append(version)
    return sorted(versions, key=semver_key)


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def validate_release_note(version: str, errors: list[str]) -> None:
    path = RELEASE_DIR / f"{version}.md"
    text = path.read_text(encoding="utf-8")
    require(
        text.startswith(f"# Entire Replay Lab {version}\n"),
        f"{path.relative_to(ROOT)} must start with '# Entire Replay Lab {version}'",
        errors,
    )
    require(
        "## What Changed" in text or "## Included" in text,
        f"{path.relative_to(ROOT)} missing section: ## What Changed or ## Included",
        errors,
    )
    for heading in ("## Why It Matters", "## Verified", "## Known Limitations"):
        require(
            heading in text,
            f"{path.relative_to(ROOT)} missing section: {heading}",
            errors,
        )
    require(
        "./scripts/verify-repo.sh" in text,
        f"{path.relative_to(ROOT)} should list verify-repo evidence",
        errors,
    )
    require(
        "GitHub Actions CI" in text,
        f"{path.relative_to(ROOT)} should mention GitHub Actions CI",
        errors,
    )


def main() -> int:
    errors: list[str] = []

    require(CHANGELOG.is_file(), "CHANGELOG.md is missing", errors)
    require(RELEASE_DIR.is_dir(), "docs/releases is missing", errors)
    if errors:
        return report(errors)

    changelog = changelog_versions()
    release_notes = release_note_versions()

    require(bool(changelog), "CHANGELOG.md has no version sections", errors)
    require(bool(release_notes), "docs/releases has no version notes", errors)
    require(
        changelog == sorted(changelog, key=semver_key, reverse=True),
        "CHANGELOG.md versions must be newest-first",
        errors,
    )
    require(
        release_notes == sorted(release_notes, key=semver_key),
        "docs/releases files must sort in semver order",
        errors,
    )
    require(
        set(changelog) == set(release_notes),
        "CHANGELOG.md versions must match docs/releases/v*.md files",
        errors,
    )

    for version in release_notes:
        validate_release_note(version, errors)

    latest = max(release_notes, key=semver_key) if release_notes else ""
    require(
        latest and changelog and changelog[0] == latest,
        f"latest changelog section should be {latest}",
        errors,
    )

    if errors:
        return report(errors)

    print(f"OK release docs for {len(release_notes)} version(s); latest {latest}.")
    return 0


def report(errors: list[str]) -> int:
    print("Release docs validation failed:", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
