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


def load_schema(path: Path, cache: dict[Path, dict[str, Any]]) -> dict[str, Any]:
    resolved = path.resolve()
    if resolved not in cache:
        schema = load_json(resolved)
        if not isinstance(schema, dict):
            raise ValidationError(f"{display_path(resolved)}: schema root must be an object")
        cache[resolved] = schema
    return cache[resolved]


def resolve_json_pointer(document: dict[str, Any], pointer: str, ref: str) -> dict[str, Any]:
    if pointer == "":
        return document
    if not pointer.startswith("/"):
        raise ValidationError(f"unsupported $ref fragment {ref!r}")
    target: Any = document
    for raw_part in pointer.lstrip("/").split("/"):
        part = raw_part.replace("~1", "/").replace("~0", "~")
        if not isinstance(target, dict) or part not in target:
            raise ValidationError(f"missing JSON pointer target for {ref!r}")
        target = target[part]
    if not isinstance(target, dict):
        raise ValidationError(f"$ref target for {ref!r} must be an object")
    return target


def resolve_ref(
    schema: dict[str, Any],
    schema_path: Path,
    ref: str,
    cache: dict[Path, dict[str, Any]],
) -> tuple[dict[str, Any], dict[str, Any], Path]:
    if "#" in ref:
        document_ref, pointer = ref.split("#", 1)
    else:
        document_ref, pointer = ref, ""

    if document_ref:
        target_path = (schema_path.parent / document_ref).resolve()
        target_schema = load_schema(target_path, cache)
    else:
        target_path = schema_path
        target_schema = schema

    target_rule = resolve_json_pointer(target_schema, pointer, ref)
    return target_schema, target_rule, target_path


def validate(
    schema: dict[str, Any],
    rule: dict[str, Any],
    value: Any,
    path: str,
    schema_path: Path,
    cache: dict[Path, dict[str, Any]],
) -> None:
    if "$ref" in rule:
        target_schema, target_rule, target_path = resolve_ref(
            schema,
            schema_path,
            str(rule["$ref"]),
            cache,
        )
        validate(target_schema, target_rule, value, path, target_path, cache)
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
        if rule.get("additionalProperties") is False:
            extra = sorted(set(value) - set(properties))
            if extra:
                raise ValidationError(
                    f"{path}: unexpected additional key(s): {', '.join(extra)}"
                )
        for key, child in properties.items():
            if key in value:
                if not isinstance(child, dict):
                    raise ValidationError(f"{path}.{key}: property schema must be an object")
                validate(schema, child, value[key], f"{path}.{key}", schema_path, cache)

    if isinstance(value, list) and "items" in rule:
        item_rule = rule["items"]
        if not isinstance(item_rule, dict):
            raise ValidationError(f"{path}: items schema must be an object")
        for index, item in enumerate(value):
            validate(schema, item_rule, item, f"{path}[{index}]", schema_path, cache)


def display_path(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def validate_path(example_path: Path, schema_path: Path) -> None:
    schema_path = schema_path.resolve()
    example = load_json(example_path)
    schema = load_json(schema_path)
    cache = {schema_path: schema}
    example_name = display_path(example_path)
    schema_name = display_path(schema_path)
    if not isinstance(schema, dict):
        raise ValidationError(f"{schema_name}: schema root must be an object")
    validate(schema, schema, example, example_name, schema_path, cache)
    print(f"OK {example_name} matches {schema_name}")


def validate_file(example_rel: str, schema_rel: str) -> None:
    validate_path(ROOT / example_rel, ROOT / schema_rel)


def validate_rejects_extra_field(example_path: Path, schema_path: Path) -> None:
    schema_path = schema_path.resolve()
    example = load_json(example_path)
    schema = load_json(schema_path)
    cache = {schema_path: schema}
    example_name = display_path(example_path)
    schema_name = display_path(schema_path)
    if not isinstance(example, dict):
        raise ValidationError(f"{example_name}: example root must be an object")
    if not isinstance(schema, dict):
        raise ValidationError(f"{schema_name}: schema root must be an object")
    mutated = dict(example)
    mutated["__unexpected_replay_lab_field__"] = True
    try:
        validate(schema, schema, mutated, f"{example_name}#negative", schema_path, cache)
    except ValidationError as exc:
        if "unexpected additional key" not in str(exc):
            raise ValidationError(
                f"{example_name}: negative additionalProperties check failed with "
                f"unexpected error: {exc}"
            ) from exc
        return
    raise ValidationError(f"{example_name}: schema accepted an undocumented extra field")


def validate_rejects_eval_run_extra_field(example_path: Path, schema_path: Path) -> None:
    schema_path = schema_path.resolve()
    if schema_path.name != "eval-run.schema.json":
        return
    example = load_json(example_path)
    schema = load_json(schema_path)
    cache = {schema_path: schema}
    example_name = display_path(example_path)
    if not isinstance(example, dict):
        raise ValidationError(f"{example_name}: example root must be an object")
    runs = example.get("runs")
    if not isinstance(runs, list) or not runs or not isinstance(runs[0], dict):
        raise ValidationError(f"{example_name}: eval example must include a replay run")
    mutated = dict(example)
    mutated_runs = [dict(run) if isinstance(run, dict) else run for run in runs]
    mutated_runs[0]["__unexpected_replay_lab_run_field__"] = True
    mutated["runs"] = mutated_runs
    try:
        validate(schema, schema, mutated, f"{example_name}#runs-negative", schema_path, cache)
    except ValidationError as exc:
        if "unexpected additional key" not in str(exc):
            raise ValidationError(
                f"{example_name}: nested run additionalProperties check failed with "
                f"unexpected error: {exc}"
            ) from exc
        return
    raise ValidationError(f"{example_name}: schema accepted an undocumented eval run field")


def checked_pairs(args: list[str]) -> list[tuple[Path, Path]]:
    if not args:
        return [
            (ROOT / "examples/replay-run.json", ROOT / "schemas/replay-run.schema.json"),
            (ROOT / "examples/eval-run.json", ROOT / "schemas/eval-run.schema.json"),
        ]
    pairs: list[tuple[Path, Path]] = []
    remaining = list(args)
    while remaining:
        if len(remaining) < 3 or remaining[0] != "--check":
            raise ValidationError(
                "usage: validate-examples.py [--check <json> <schema>]..."
            )
        pairs.append((Path(remaining[1]), Path(remaining[2])))
        del remaining[:3]
    return pairs


def main() -> int:
    try:
        for example, schema in checked_pairs(sys.argv[1:]):
            validate_path(example, schema)
            validate_rejects_extra_field(example, schema)
            validate_rejects_eval_run_extra_field(example, schema)
    except (OSError, json.JSONDecodeError, ValidationError) as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
