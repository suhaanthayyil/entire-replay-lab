#!/usr/bin/env python3
"""Validate local Markdown links in Replay Lab docs."""

from __future__ import annotations

import re
import string
import sys
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
DOCS = [
    ROOT / "README.md",
    ROOT / "CONTRIBUTING.md",
    ROOT / "SECURITY.md",
    *sorted((ROOT / "docs").glob("**/*.md")),
]

EXTERNAL_PREFIXES = (
    "http://",
    "https://",
    "mailto:",
    "tel:",
    "//",
)


def strip_inline_code(line: str) -> str:
    return re.sub(r"`[^`\n]*`", "", line)


def link_target(raw: str) -> str:
    value = raw.strip()
    if value.startswith("<") and ">" in value:
        return value[1 : value.index(">")].strip()
    return value.split()[0] if value.split() else ""


def iter_links(path: Path):
    in_fence = False
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue

        line = strip_inline_code(line)
        start = 0
        while True:
            marker = line.find("](", start)
            if marker == -1:
                break
            target_start = marker + 2
            target_end = line.find(")", target_start)
            if target_end == -1:
                break
            target = link_target(line[target_start:target_end])
            if target:
                yield line_no, target
            start = target_end + 1


def github_slug(text: str) -> str:
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"[`*_~]", "", text).strip().lower()
    allowed = set(string.ascii_lowercase + string.digits + " -")
    text = "".join(ch for ch in text if ch in allowed)
    return re.sub(r"-+", "-", re.sub(r"\s+", "-", text)).strip("-")


def markdown_anchors(path: Path) -> set[str]:
    anchors: set[str] = set()
    counts: dict[str, int] = {}
    heading_re = re.compile(r"^(#{1,6})\s+(.+?)\s*#*\s*$")
    for line in path.read_text(encoding="utf-8").splitlines():
        match = heading_re.match(line)
        if not match:
            continue
        slug = github_slug(match.group(2))
        if not slug:
            continue
        count = counts.get(slug, 0)
        counts[slug] = count + 1
        anchors.add(slug if count == 0 else f"{slug}-{count}")
    return anchors


def is_external(target: str) -> bool:
    lower = target.lower()
    return lower.startswith(EXTERNAL_PREFIXES)


def resolve_local_link(source: Path, target: str) -> tuple[Path, str]:
    target = unquote(target)
    path_part, _, anchor = target.partition("#")
    path_part = path_part.split("?", 1)[0]
    if not path_part:
        return source, anchor
    return (source.parent / path_part).resolve(), anchor


def main() -> int:
    errors: list[str] = []
    anchor_cache: dict[Path, set[str]] = {}

    for doc in DOCS:
        if not doc.exists():
            errors.append(f"missing doc file: {doc.relative_to(ROOT)}")
            continue
        for line_no, target in iter_links(doc):
            if target.startswith("#") or is_external(target):
                continue

            resolved, anchor = resolve_local_link(doc, target)
            try:
                resolved.relative_to(ROOT)
            except ValueError:
                errors.append(
                    f"{doc.relative_to(ROOT)}:{line_no}: link escapes repo: {target}"
                )
                continue

            if not resolved.exists():
                errors.append(
                    f"{doc.relative_to(ROOT)}:{line_no}: missing link target: {target}"
                )
                continue

            if anchor and resolved.suffix == ".md":
                anchors = anchor_cache.setdefault(resolved, markdown_anchors(resolved))
                if anchor.lower() not in anchors:
                    errors.append(
                        f"{doc.relative_to(ROOT)}:{line_no}: missing anchor #{anchor} in "
                        f"{resolved.relative_to(ROOT)}"
                    )

    if errors:
        print("Markdown link validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"OK markdown links in {len(DOCS)} file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
