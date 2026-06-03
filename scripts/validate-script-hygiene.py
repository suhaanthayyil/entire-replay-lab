#!/usr/bin/env python3
"""Validate Replay Lab helper script hygiene and command reference coverage."""

from __future__ import annotations

import os
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = ROOT / "scripts"
COMMANDS_DOC = ROOT / "docs" / "COMMANDS.md"


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def validate_shell_script(path: Path, text: str, errors: list[str]) -> None:
    rel = path.relative_to(ROOT)
    require(
        text.startswith("#!/usr/bin/env bash\n"),
        f"{rel} must start with '#!/usr/bin/env bash'",
        errors,
    )
    if path.name != "replay-lab-env.sh":
        require(
            "set -euo pipefail" in text.splitlines()[:6],
            f"{rel} must enable 'set -euo pipefail' near the top",
            errors,
        )
    else:
        require(
            "Shared Replay Lab build inputs" in text,
            f"{rel} should explain that it is a sourceable env helper",
            errors,
        )


def validate_python_script(path: Path, text: str, errors: list[str]) -> None:
    rel = path.relative_to(ROOT)
    require(
        text.startswith("#!/usr/bin/env python3\n"),
        f"{rel} must start with '#!/usr/bin/env python3'",
        errors,
    )
    require(
        'if __name__ == "__main__":' in text,
        f"{rel} must have a CLI entrypoint guard",
        errors,
    )
    require(
        "raise SystemExit(main())" in text,
        f"{rel} must exit through main()",
        errors,
    )


def validate_commands_doc(script_names: list[str], errors: list[str]) -> None:
    if not COMMANDS_DOC.is_file():
        errors.append("docs/COMMANDS.md is missing")
        return
    text = COMMANDS_DOC.read_text(encoding="utf-8")
    for script in script_names:
        require(
            f"### `./scripts/{script}" in text,
            f"docs/COMMANDS.md missing section for ./scripts/{script}",
            errors,
        )


def main() -> int:
    errors: list[str] = []
    scripts = sorted(path for path in SCRIPTS_DIR.iterdir() if path.is_file())

    for path in scripts:
        rel = path.relative_to(ROOT)
        mode = path.stat().st_mode
        require(os.access(path, os.X_OK), f"{rel} must be executable", errors)
        text = path.read_text(encoding="utf-8")
        if path.suffix == ".sh":
            validate_shell_script(path, text, errors)
        elif path.suffix == ".py":
            validate_python_script(path, text, errors)
        else:
            errors.append(f"{rel} has unsupported script extension")
        require(mode & 0o111, f"{rel} must have executable permission bits", errors)

    validate_commands_doc([path.name for path in scripts], errors)

    if errors:
        print("Script hygiene validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"OK script hygiene and command docs for {len(scripts)} script(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
