#!/usr/bin/env python3
"""Validate Replay Lab example JSON against the local schema subset.

This intentionally avoids third-party dependencies. It implements the JSON
Schema features used by this repo's schemas, not the full JSON Schema spec.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]


class ValidationError(Exception):
    pass


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def type_name(value: Any) -> str:
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int) and not isinstance(value, bool):
        return "integer"
    if isinstance(value, float):
        return "number"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    if value is None:
        return "null"
    return type(value).__name__


def resolve_ref(schema: dict[str, Any], ref: str) -> dict[str, Any]:
    prefix = "#/$defs/"
    if not ref.startswith(prefix):
        raise ValidationError(f"unsupported $ref {ref!r}")
    name = ref[len(prefix) :]
    try:
        target = schema["$defs"][name]
    except KeyError as exc:
        raise ValidationError(f"missing $defs entry for {ref!r}") from exc
    if not isinstance(target, dict):
        raise ValidationError(f"$defs entry {name!r} must be an object")
    return target


def validate(schema: dict[str, Any], rule: dict[str, Any], value: Any, path: str) -> None:
    if "$ref" in rule:
        validate(schema, resolve_ref(schema, str(rule["$ref"])), value, path)
        return

    if "const" in rule and value != rule["const"]:
        raise ValidationError(f"{path}: expected const {rule['const']!r}, got {value!r}")

    if "enum" in rule and value not in rule["enum"]:
        raise ValidationError(f"{path}: expected one of {rule['enum']!r}, got {value!r}")

    expected_type = rule.get("type")
    if expected_type is not None:
        expected = [expected_type] if isinstance(expected_type, str) else list(expected_type)
        actual = type_name(value)
        if actual not in expected:
            raise ValidationError(f"{path}: expected type {expected!r}, got {actual}")

    if type_name(value) == "integer":
        minimum = rule.get("minimum")
        maximum = rule.get("maximum")
        if minimum is not None and value < minimum:
            raise ValidationError(f"{path}: expected >= {minimum}, got {value}")
        if maximum is not None and value > maximum:
            raise ValidationError(f"{path}: expected <= {maximum}, got {value}")

    if isinstance(value, dict):
        required = rule.get("required", [])
        for key in required:
            if key not in value:
                raise ValidationError(f"{path}: missing required key {key!r}")

        properties = rule.get("properties", {})
        if not isinstance(properties, dict):
            raise ValidationError(f"{path}: properties must be an object")
        for key, child in properties.items():
            if key in value:
                if not isinstance(child, dict):
                    raise ValidationError(f"{path}.{key}: property schema must be an object")
                validate(schema, child, value[key], f"{path}.{key}")

    if isinstance(value, list) and "items" in rule:
        item_rule = rule["items"]
        if not isinstance(item_rule, dict):
            raise ValidationError(f"{path}: items schema must be an object")
        for index, item in enumerate(value):
            validate(schema, item_rule, item, f"{path}[{index}]")


def validate_file(example_rel: str, schema_rel: str) -> None:
    example_path = ROOT / example_rel
    schema_path = ROOT / schema_rel
    example = load_json(example_path)
    schema = load_json(schema_path)
    if not isinstance(schema, dict):
        raise ValidationError(f"{schema_rel}: schema root must be an object")
    validate(schema, schema, example, example_rel)
    print(f"OK {example_rel} matches {schema_rel}")


def main() -> int:
    pairs = [
        ("examples/replay-run.json", "schemas/replay-run.schema.json"),
        ("examples/eval-run.json", "schemas/eval-run.schema.json"),
    ]
    try:
        for example, schema in pairs:
            validate_file(example, schema)
    except (OSError, json.JSONDecodeError, ValidationError) as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
