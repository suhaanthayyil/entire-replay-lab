#!/usr/bin/env python3
"""Validate Markdown fenced code blocks in Replay Lab docs."""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = [
    ROOT / "README.md",
    ROOT / "CONTRIBUTING.md",
    ROOT / "SECURITY.md",
    *sorted((ROOT / "docs").glob("**/*.md")),
]
ALLOWED_INFO = {"", "bash", "json", "mermaid", "sh", "text"}
FENCE_RE = re.compile(r"^(\s*)(`{3,}|~{3,})([^`]*)$")


@dataclass
class Fence:
    marker: str
    length: int
    info: str
    start_line: int
    lines: list[str]


def fence_close(line: str, fence: Fence) -> bool:
    stripped = line.strip()
    return stripped.startswith(fence.marker * fence.length) and set(stripped) == {
        fence.marker
    }


def normalize_info(raw: str) -> str:
    return raw.strip().split(None, 1)[0].lower()


def validate_json(path: Path, fence: Fence, errors: list[str]) -> None:
    text = "\n".join(fence.lines).strip()
    if not text:
        errors.append(f"{path.relative_to(ROOT)}:{fence.start_line}: empty json fence")
        return
    try:
        json.loads(text)
    except json.JSONDecodeError as exc:
        errors.append(
            f"{path.relative_to(ROOT)}:{fence.start_line}: invalid json fence: "
            f"{exc.msg} at line {exc.lineno}, column {exc.colno}"
        )


def finish_fence(path: Path, fence: Fence, errors: list[str]) -> None:
    if fence.info not in ALLOWED_INFO:
        errors.append(
            f"{path.relative_to(ROOT)}:{fence.start_line}: unsupported fence language "
            f"{fence.info!r}"
        )
    if fence.info == "json":
        validate_json(path, fence, errors)


def validate_doc(path: Path, errors: list[str]) -> None:
    active: Fence | None = None
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if active is not None:
            if fence_close(line, active):
                finish_fence(path, active, errors)
                active = None
            else:
                active.lines.append(line)
            continue

        match = FENCE_RE.match(line)
        if not match:
            continue
        marker = match.group(2)
        active = Fence(
            marker=marker[0],
            length=len(marker),
            info=normalize_info(match.group(3)),
            start_line=line_no,
            lines=[],
        )

    if active is not None:
        errors.append(
            f"{path.relative_to(ROOT)}:{active.start_line}: unclosed {active.marker * active.length} fence"
        )


def main() -> int:
    errors: list[str] = []
    for doc in DOCS:
        if not doc.exists():
            errors.append(f"missing doc file: {doc.relative_to(ROOT)}")
            continue
        validate_doc(doc, errors)

    if errors:
        print("Markdown fence validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"OK markdown fences in {len(DOCS)} file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
