#!/usr/bin/env python3
"""Validate that reusable Replay Lab docs and scripts are machine-portable."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

SKIP_DIRS = {
    ".git",
    "bin",
    "tmp",
    "__pycache__",
}
SKIP_FILES = {
    "patches/entire-replay-lab.patch",
    "scripts/validate-portability.py",
}

BLOCKED_PATTERNS = [
    (re.compile(r"/Users/suhaan\b"), "personal macOS home path"),
    (re.compile(r"/Users/[A-Za-z0-9._-]+/Documents/Coding\b"), "personal coding path"),
    (re.compile(r"/private/tmp\b"), "ephemeral macOS temp path"),
    (re.compile(r"/var/folders\b"), "ephemeral macOS temp path"),
    (re.compile(r"(?:~|\$HOME)/Documents/Ultron\b"), "personal demo repo path"),
    (re.compile(r"\bDocuments/Ultron\b"), "personal demo repo path"),
]


def iter_text_files() -> list[Path]:
    files: list[Path] = []
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        if rel.as_posix() in SKIP_FILES:
            continue
        if len(rel.parts) >= 2 and rel.parts[0] == "docs" and rel.parts[1] == "releases":
            continue
        if path.suffix in {".md", ".py", ".sh", ".yml", ".yaml"} or path.name in {
            "Makefile",
            "LICENSE",
            "CHANGELOG.md",
        }:
            files.append(path)
    return sorted(files)


def main() -> int:
    errors: list[str] = []
    for path in iter_text_files():
        rel = path.relative_to(ROOT)
        text = path.read_text(encoding="utf-8")
        for line_no, line in enumerate(text.splitlines(), 1):
            for pattern, reason in BLOCKED_PATTERNS:
                if pattern.search(line):
                    errors.append(f"{rel}:{line_no}: {reason}: {line.strip()}")

    if errors:
        print("Portability validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("OK reusable docs and scripts avoid machine-specific local paths.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
