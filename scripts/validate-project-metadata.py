#!/usr/bin/env python3
"""Validate Replay Lab project metadata and license hygiene."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

EXPECTED_README_SNIPPETS = [
    "# Entire Replay Lab",
    "[![CI](https://github.com/suhaanthayyil/entire-replay-lab/actions/workflows/ci.yml/badge.svg)]",
    "[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)",
    "[![Prototype](https://img.shields.io/badge/status-prototype-orange.svg)]",
    "Private, repo-specific agent evaluation from real Entire checkpoints.",
    "This repo is the product and demo home for the prototype.",
    "The runnable implementation is captured in `patches/entire-replay-lab.patch`.",
    "## License",
    "MIT.",
]

EXPECTED_LICENSE_SNIPPETS = [
    "MIT License",
    "Copyright (c) 2026 Suhaan Thayyil",
    "Permission is hereby granted, free of charge, to any person obtaining a copy",
    'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND',
]

EXPECTED_CONTRIBUTING_SNIPPETS = [
    "Keep the patch MIT-compatible.",
    "Do not add network calls outside normal agent execution.",
]

EXPECTED_SECURITY_SNIPPETS = [
    "Replay Lab runs coding agents and optional test commands in isolated git",
    "Replay JSON is stored under `.git/entire-replay/`",
]

BLOCKED_LICENSE_WORDS = [
    "all rights reserved",
    "proprietary",
    "non-commercial",
    "apache license",
    "gpl",
    "agpl",
]


def read(path: Path, errors: list[str]) -> str:
    if not path.is_file():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def require_snippets(name: str, text: str, snippets: list[str], errors: list[str]) -> None:
    for snippet in snippets:
        if snippet not in text:
            errors.append(f"{name} missing required text: {snippet}")


def validate_license(text: str, errors: list[str]) -> None:
    require_snippets("LICENSE", text, EXPECTED_LICENSE_SNIPPETS, errors)
    if not text.startswith("MIT License\n\n"):
        errors.append("LICENSE must start with the standard MIT heading")
    if "Entire" in text:
        errors.append("LICENSE should identify this repo owner, not imply Entire ownership")


def validate_readme(text: str, errors: list[str]) -> None:
    require_snippets("README.md", text, EXPECTED_README_SNIPPETS, errors)
    if not re.search(r"^## License\n\nMIT\.\s*$", text, re.MULTILINE):
        errors.append("README.md license section must be exactly MIT")


def validate_no_conflicting_license_text(paths: list[Path], errors: list[str]) -> None:
    for path in paths:
        text = path.read_text(encoding="utf-8").lower()
        for blocked in BLOCKED_LICENSE_WORDS:
            if blocked in text:
                errors.append(
                    f"{path.relative_to(ROOT)} contains conflicting license wording: {blocked}"
                )


def main() -> int:
    errors: list[str] = []
    license_text = read(ROOT / "LICENSE", errors)
    readme_text = read(ROOT / "README.md", errors)
    contributing_text = read(ROOT / "CONTRIBUTING.md", errors)
    security_text = read(ROOT / "SECURITY.md", errors)

    if license_text:
        validate_license(license_text, errors)
    if readme_text:
        validate_readme(readme_text, errors)
    if contributing_text:
        require_snippets(
            "CONTRIBUTING.md", contributing_text, EXPECTED_CONTRIBUTING_SNIPPETS, errors
        )
    if security_text:
        require_snippets("SECURITY.md", security_text, EXPECTED_SECURITY_SNIPPETS, errors)

    validate_no_conflicting_license_text(
        [path for path in (ROOT / "docs").glob("**/*.md") if path.is_file()],
        errors,
    )

    if errors:
        print("Project metadata validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("OK project metadata and MIT license hygiene.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
