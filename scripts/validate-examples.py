#!/usr/bin/env python3
"""Validate Replay Lab example JSON against the local schema subset.

This intentionally avoids third-party dependencies. It implements the JSON
Schema features used by this repo's schemas, not the full JSON Schema spec.
"""

from __future__ import annotations

import json
import re
import sys
from copy import deepcopy
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DATE_TIME_RE = re.compile(
    r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$"
)


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


def parse_date_time(value: str) -> datetime:
    if DATE_TIME_RE.fullmatch(value) is None:
        raise ValueError("expected RFC3339 date-time shape")
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def format_date_time(value: datetime) -> str:
    value = value.astimezone(timezone.utc)
    text = value.isoformat(timespec="seconds")
    return text.replace("+00:00", "Z")


def is_date_time(value: str) -> bool:
    try:
        parse_date_time(value)
    except ValueError:
        return False
    return True


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

    if isinstance(value, str):
        min_length = rule.get("minLength")
        if min_length is not None and len(value) < min_length:
            raise ValidationError(
                f"{path}: expected string length >= {min_length}, got {len(value)}"
            )
        pattern = rule.get("pattern")
        if pattern is not None:
            try:
                matches_pattern = re.search(str(pattern), value) is not None
            except re.error as exc:
                raise ValidationError(
                    f"{path}: invalid string pattern {pattern!r}: {exc}"
                ) from exc
            if not matches_pattern:
                raise ValidationError(f"{path}: expected string matching pattern {pattern!r}")
        format_name = rule.get("format")
        if format_name is not None:
            if format_name == "date-time":
                if not is_date_time(value):
                    raise ValidationError(f"{path}: expected RFC3339 date-time string")
            else:
                raise ValidationError(f"{path}: unsupported string format {format_name!r}")

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

    if isinstance(value, list):
        if rule.get("uniqueItems") is True:
            seen: dict[str, int] = {}
            for index, item in enumerate(value):
                key = json.dumps(item, sort_keys=True, separators=(",", ":"))
                if key in seen:
                    raise ValidationError(
                        f"{path}: expected unique array items; duplicate at "
                        f"indexes {seen[key]} and {index}"
                    )
                seen[key] = index
        if "items" in rule:
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


def validate_rejects_invalid_required_strings(
    example_path: Path,
    schema_path: Path,
    require_nested_examples: bool,
) -> None:
    schema_path = schema_path.resolve()
    example = load_json(example_path)
    schema = load_json(schema_path)
    example_name = display_path(example_path)
    schema_name = display_path(schema_path)
    if not isinstance(example, dict):
        raise ValidationError(f"{example_name}: example root must be an object")
    if not isinstance(schema, dict):
        raise ValidationError(f"{schema_name}: schema root must be an object")

    cases: list[tuple[str, dict[str, Any], str]] = []

    def add_case(case_path: str, mutated_case: dict[str, Any], expected: str) -> None:
        cases.append((case_path, mutated_case, expected))

    mutated = dict(example)
    mutated["id"] = ""
    add_case("id", mutated, "expected string length >=")
    mutated = dict(example)
    mutated["id"] = "   "
    add_case("id.blank", mutated, "expected string matching pattern")

    if require_nested_examples and schema_path.name == "replay-run.schema.json":
        spec = example.get("spec")
        if not isinstance(spec, dict):
            raise ValidationError(f"{example_name}.spec: expected object")
        for key in ("checkpoint_id", "prompt", "target_commit", "base_commit"):
            mutated = deepcopy(example)
            mutated["spec"][key] = ""
            add_case(f"spec.{key}", mutated, "expected string length >=")
            mutated = deepcopy(example)
            mutated["spec"][key] = "   "
            add_case(f"spec.{key}.blank", mutated, "expected string matching pattern")
        mutated = dict(example)
        mutated["agent"] = ""
        add_case("agent", mutated, "expected string length >=")
        mutated = dict(example)
        mutated["agent"] = "   "
        add_case("agent.blank", mutated, "expected string matching pattern")

    if require_nested_examples and schema_path.name == "eval-run.schema.json":
        agents = example.get("agents")
        summaries = example.get("summaries")
        if not isinstance(agents, list) or not agents:
            raise ValidationError(f"{example_name}.agents: expected non-empty array")
        if not isinstance(summaries, list) or not summaries or not isinstance(summaries[0], dict):
            raise ValidationError(f"{example_name}.summaries[0]: expected object")
        mutated = deepcopy(example)
        mutated["agents"][0] = ""
        add_case("agents[0]", mutated, "expected string length >=")
        mutated = deepcopy(example)
        mutated["agents"][0] = "   "
        add_case("agents[0].blank", mutated, "expected string matching pattern")
        mutated = deepcopy(example)
        mutated["summaries"][0]["agent"] = ""
        add_case("summaries[0].agent", mutated, "expected string length >=")
        mutated = deepcopy(example)
        mutated["summaries"][0]["agent"] = "   "
        add_case("summaries[0].agent.blank", mutated, "expected string matching pattern")

    for case_path, mutated_case, expected in cases:
        cache = {schema_path: schema}
        try:
            validate(
                schema,
                schema,
                mutated_case,
                f"{example_name}#empty-{case_path}",
                schema_path,
                cache,
            )
        except ValidationError as exc:
            if expected not in str(exc):
                raise ValidationError(
                    f"{example_name}: invalid string check for {case_path} failed "
                    f"with unexpected error: {exc}"
                ) from exc
            continue
        raise ValidationError(
            f"{example_name}: schema accepted invalid required string {case_path}"
        )


def duplicate_first_string(values: Any) -> list[str] | None:
    if not isinstance(values, list) or not values:
        return None
    first = values[0]
    if not isinstance(first, str):
        return None
    return [first, first, *values[1:]]


def validate_rejects_invalid_file_array_items(
    example_path: Path,
    schema_path: Path,
    require_nested_examples: bool,
) -> None:
    schema_path = schema_path.resolve()
    example = load_json(example_path)
    schema = load_json(schema_path)
    example_name = display_path(example_path)
    schema_name = display_path(schema_path)
    if not isinstance(example, dict):
        raise ValidationError(f"{example_name}: example root must be an object")
    if not isinstance(schema, dict):
        raise ValidationError(f"{schema_name}: schema root must be an object")

    cases: list[tuple[str, dict[str, Any], str]] = []

    def add_cases(case_path: str, mutator: Any) -> None:
        mutated = deepcopy(example)
        mutator(mutated, "")
        cases.append((case_path, mutated, "expected string length >="))
        mutated = deepcopy(example)
        mutator(mutated, "   ")
        cases.append((f"{case_path}.blank", mutated, "expected string matching pattern"))

    def set_top_array(key: str) -> Any:
        return lambda mutated, value: mutated.__setitem__(key, [value])

    def set_spec_array(key: str) -> Any:
        return lambda mutated, value: mutated["spec"].__setitem__(key, [value])

    def set_metric_array(key: str) -> Any:
        return lambda mutated, value: mutated["metrics"].__setitem__(key, [value])

    def set_run_array(index: int, key: str) -> Any:
        return lambda mutated, value: mutated["runs"][index].__setitem__(key, [value])

    def set_run_spec_array(index: int, key: str) -> Any:
        return lambda mutated, value: mutated["runs"][index]["spec"].__setitem__(key, [value])

    def set_run_metric_array(index: int, key: str) -> Any:
        return lambda mutated, value: mutated["runs"][index]["metrics"].__setitem__(key, [value])

    if schema_path.name == "replay-run.schema.json":
        add_cases("changed_files[0]", set_top_array("changed_files"))
        spec = example.get("spec")
        if require_nested_examples and not isinstance(spec, dict):
            raise ValidationError(f"{example_name}.spec: expected object")
        if isinstance(spec, dict):
            add_cases("spec.files_touched[0]", set_spec_array("files_touched"))
        metrics = example.get("metrics")
        if isinstance(metrics, dict):
            for key in ("missing_files", "extra_files", "risky_files"):
                add_cases(f"metrics.{key}[0]", set_metric_array(key))

    if require_nested_examples and schema_path.name == "eval-run.schema.json":
        runs = example.get("runs")
        if not isinstance(runs, list) or not runs:
            raise ValidationError(f"{example_name}.runs: expected non-empty array")
        for index, run in enumerate(runs):
            if not isinstance(run, dict):
                continue
            add_cases(f"runs[{index}].changed_files[0]", set_run_array(index, "changed_files"))
            if isinstance(run.get("spec"), dict):
                add_cases(
                    f"runs[{index}].spec.files_touched[0]",
                    set_run_spec_array(index, "files_touched"),
                )
            if isinstance(run.get("metrics"), dict):
                for key in ("missing_files", "extra_files", "risky_files"):
                    add_cases(
                        f"runs[{index}].metrics.{key}[0]",
                        set_run_metric_array(index, key),
                    )
            break

    for case_path, mutated_case, expected in cases:
        cache = {schema_path: schema}
        try:
            validate(
                schema,
                schema,
                mutated_case,
                f"{example_name}#invalid-file-{case_path}",
                schema_path,
                cache,
            )
        except ValidationError as exc:
            if expected not in str(exc):
                raise ValidationError(
                    f"{example_name}: invalid file-array check for {case_path} "
                    f"failed with unexpected error: {exc}"
                ) from exc
            continue
        raise ValidationError(
            f"{example_name}: schema accepted invalid file-array item in {case_path}"
        )


def validate_rejects_invalid_date_times(
    example_path: Path,
    schema_path: Path,
    require_nested_examples: bool,
) -> None:
    schema_path = schema_path.resolve()
    example = load_json(example_path)
    schema = load_json(schema_path)
    example_name = display_path(example_path)
    schema_name = display_path(schema_path)
    if not isinstance(example, dict):
        raise ValidationError(f"{example_name}: example root must be an object")
    if not isinstance(schema, dict):
        raise ValidationError(f"{schema_name}: schema root must be an object")

    cases: list[tuple[str, dict[str, Any]]] = []

    def add_case(case_path: str, mutated_case: dict[str, Any]) -> None:
        cases.append((case_path, mutated_case))

    for key in ("started_at", "finished_at"):
        if key in example:
            mutated = deepcopy(example)
            mutated[key] = "not-a-date"
            add_case(key, mutated)

    if require_nested_examples and schema_path.name == "eval-run.schema.json":
        runs = example.get("runs")
        if not isinstance(runs, list) or not runs:
            raise ValidationError(f"{example_name}.runs: expected non-empty array")
        for index, run in enumerate(runs):
            if not isinstance(run, dict):
                continue
            for key in ("started_at", "finished_at"):
                if key in run:
                    mutated = deepcopy(example)
                    mutated["runs"][index][key] = "not-a-date"
                    add_case(f"runs[{index}].{key}", mutated)
            break

    for case_path, mutated_case in cases:
        cache = {schema_path: schema}
        try:
            validate(
                schema,
                schema,
                mutated_case,
                f"{example_name}#invalid-date-{case_path}",
                schema_path,
                cache,
            )
        except ValidationError as exc:
            if "expected RFC3339 date-time string" not in str(exc):
                raise ValidationError(
                    f"{example_name}: date-time check for {case_path} failed "
                    f"with unexpected error: {exc}"
                ) from exc
            continue
        raise ValidationError(f"{example_name}: schema accepted invalid date-time {case_path}")


def validate_date_time_order_in_report(report: dict[str, Any], path: str) -> None:
    started = report.get("started_at")
    finished = report.get("finished_at")
    if not isinstance(started, str) or not isinstance(finished, str):
        return
    started_at = parse_date_time(started)
    finished_at = parse_date_time(finished)
    if finished_at < started_at:
        raise ValidationError(
            f"{path}: finished_at must be greater than or equal to started_at"
        )


def validate_date_time_order(example_path: Path, schema_path: Path) -> None:
    schema_name = schema_path.resolve().name
    if schema_name not in {"replay-run.schema.json", "eval-run.schema.json"}:
        return
    example = load_json(example_path)
    example_name = display_path(example_path)
    if not isinstance(example, dict):
        raise ValidationError(f"{example_name}: example root must be an object")
    validate_date_time_order_in_report(example, example_name)
    if schema_name != "eval-run.schema.json":
        return
    runs = example.get("runs", [])
    if not isinstance(runs, list):
        raise ValidationError(f"{example_name}.runs: expected array")
    for index, run in enumerate(runs):
        if not isinstance(run, dict):
            raise ValidationError(f"{example_name}.runs[{index}]: expected object")
        validate_date_time_order_in_report(run, f"{example_name}.runs[{index}]")


def validate_rejects_inverted_date_times(
    example_path: Path,
    schema_path: Path,
    require_nested_examples: bool,
) -> None:
    schema_name = schema_path.resolve().name
    if schema_name not in {"replay-run.schema.json", "eval-run.schema.json"}:
        return
    example = load_json(example_path)
    example_name = display_path(example_path)
    if not isinstance(example, dict):
        raise ValidationError(f"{example_name}: example root must be an object")

    cases: list[tuple[str, dict[str, Any]]] = []

    def invert_report_time(report: dict[str, Any]) -> None:
        started = report.get("started_at")
        if not isinstance(started, str):
            raise ValidationError(f"{example_name}: expected started_at string")
        started_at = parse_date_time(started)
        report["finished_at"] = format_date_time(started_at - timedelta(seconds=1))

    mutated = deepcopy(example)
    invert_report_time(mutated)
    cases.append(("finished_at", mutated))

    if require_nested_examples and schema_name == "eval-run.schema.json":
        runs = example.get("runs")
        if not isinstance(runs, list) or not runs:
            raise ValidationError(f"{example_name}.runs: expected non-empty array")
        for index, run in enumerate(runs):
            if not isinstance(run, dict):
                continue
            mutated = deepcopy(example)
            invert_report_time(mutated["runs"][index])
            cases.append((f"runs[{index}].finished_at", mutated))
            break

    for case_path, mutated_case in cases:
        with tempfile_json(example_path.name, mutated_case) as mutated_path:
            try:
                validate_date_time_order(mutated_path, schema_path)
            except ValidationError as exc:
                if "finished_at must be greater than or equal to started_at" not in str(exc):
                    raise ValidationError(
                        f"{example_name}: inverted date-time check for {case_path} "
                        f"failed with unexpected error: {exc}"
                    ) from exc
                continue
        raise ValidationError(f"{example_name}: validator accepted inverted {case_path}")


def validate_rejects_duplicate_unique_arrays(
    example_path: Path,
    schema_path: Path,
    require_nested_examples: bool,
) -> None:
    schema_path = schema_path.resolve()
    example = load_json(example_path)
    schema = load_json(schema_path)
    example_name = display_path(example_path)
    schema_name = display_path(schema_path)
    if not isinstance(example, dict):
        raise ValidationError(f"{example_name}: example root must be an object")
    if not isinstance(schema, dict):
        raise ValidationError(f"{schema_name}: schema root must be an object")

    cases: list[tuple[str, dict[str, Any]]] = []

    def add_case(case_path: str, mutated_case: dict[str, Any]) -> None:
        cases.append((case_path, mutated_case))

    def add_metric_cases(root: dict[str, Any], prefix: str) -> None:
        metrics = root.get("metrics")
        if not isinstance(metrics, dict):
            return
        for key in ("missing_files", "extra_files", "risky_files"):
            duplicated = duplicate_first_string(metrics.get(key))
            if duplicated is None:
                continue
            mutated_case = deepcopy(example)
            target: dict[str, Any] = mutated_case
            if prefix:
                for part in prefix.split("."):
                    if part.endswith("]"):
                        name, raw_index = part[:-1].split("[", 1)
                        target = target[name][int(raw_index)]
                    else:
                        target = target[part]
            target["metrics"][key] = duplicated
            add_case(f"{prefix + '.' if prefix else ''}metrics.{key}", mutated_case)

    if schema_path.name == "replay-run.schema.json":
        duplicated = duplicate_first_string(example.get("changed_files"))
        if duplicated is not None:
            mutated = deepcopy(example)
            mutated["changed_files"] = duplicated
            add_case("changed_files", mutated)

        if require_nested_examples:
            spec = example.get("spec")
            if not isinstance(spec, dict):
                raise ValidationError(f"{example_name}.spec: expected object")
            duplicated = duplicate_first_string(spec.get("files_touched"))
            if duplicated is not None:
                mutated = deepcopy(example)
                mutated["spec"]["files_touched"] = duplicated
                add_case("spec.files_touched", mutated)
        add_metric_cases(example, "")

    if require_nested_examples and schema_path.name == "eval-run.schema.json":
        duplicated = duplicate_first_string(example.get("agents"))
        if duplicated is not None:
            mutated = deepcopy(example)
            mutated["agents"] = duplicated
            add_case("agents", mutated)

        runs = example.get("runs")
        if isinstance(runs, list):
            for index, run in enumerate(runs):
                if not isinstance(run, dict):
                    continue
                duplicated = duplicate_first_string(run.get("changed_files"))
                if duplicated is not None:
                    mutated = deepcopy(example)
                    mutated["runs"][index]["changed_files"] = duplicated
                    add_case(f"runs[{index}].changed_files", mutated)
                spec = run.get("spec")
                if isinstance(spec, dict):
                    duplicated = duplicate_first_string(spec.get("files_touched"))
                    if duplicated is not None:
                        mutated = deepcopy(example)
                        mutated["runs"][index]["spec"]["files_touched"] = duplicated
                        add_case(f"runs[{index}].spec.files_touched", mutated)
                add_metric_cases(run, f"runs[{index}]")

    for case_path, mutated_case in cases:
        cache = {schema_path: schema}
        try:
            validate(
                schema,
                schema,
                mutated_case,
                f"{example_name}#duplicate-{case_path}",
                schema_path,
                cache,
            )
        except ValidationError as exc:
            if "expected unique array items" not in str(exc):
                raise ValidationError(
                    f"{example_name}: duplicate array check for {case_path} failed "
                    f"with unexpected error: {exc}"
                ) from exc
            continue
        raise ValidationError(
            f"{example_name}: schema accepted duplicate array item in {case_path}"
        )


def set_path_value(root: Any, segments: list[str | int], value: Any) -> None:
    target = root
    for segment in segments[:-1]:
        target = target[segment]
    target[segments[-1]] = value


def path_value(root: Any, segments: list[str | int]) -> Any:
    target = root
    for segment in segments:
        target = target[segment]
    return target


def collect_closed_object_cases(
    schema: dict[str, Any],
    rule: dict[str, Any],
    value: Any,
    path: str,
    segments: list[str | int],
    schema_path: Path,
    cache: dict[Path, dict[str, Any]],
) -> list[tuple[str, list[str | int]]]:
    if "$ref" in rule:
        target_schema, target_rule, target_path = resolve_ref(
            schema,
            schema_path,
            str(rule["$ref"]),
            cache,
        )
        return collect_closed_object_cases(
            target_schema,
            target_rule,
            value,
            path,
            segments,
            target_path,
            cache,
        )

    cases: list[tuple[str, list[str | int]]] = []
    if isinstance(value, dict):
        if rule.get("additionalProperties") is False:
            cases.append((path, list(segments)))
        properties = rule.get("properties", {})
        if not isinstance(properties, dict):
            raise ValidationError(f"{path}: properties must be an object")
        for key, child in properties.items():
            if key not in value:
                continue
            if not isinstance(child, dict):
                raise ValidationError(f"{path}.{key}: property schema must be an object")
            cases.extend(
                collect_closed_object_cases(
                    schema,
                    child,
                    value[key],
                    f"{path}.{key}",
                    [*segments, key],
                    schema_path,
                    cache,
                )
            )

    if isinstance(value, list) and "items" in rule:
        item_rule = rule["items"]
        if not isinstance(item_rule, dict):
            raise ValidationError(f"{path}: items schema must be an object")
        for index, item in enumerate(value):
            cases.extend(
                collect_closed_object_cases(
                    schema,
                    item_rule,
                    item,
                    f"{path}[{index}]",
                    [*segments, index],
                    schema_path,
                    cache,
                )
            )

    return cases


def validate_rejects_closed_object_extra_fields(
    example_path: Path,
    schema_path: Path,
) -> None:
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

    cases = collect_closed_object_cases(
        schema,
        schema,
        example,
        example_name,
        [],
        schema_path,
        cache,
    )
    for case_path, segments in cases:
        mutated = deepcopy(example)
        target = path_value(mutated, segments)
        if not isinstance(target, dict):
            raise ValidationError(f"{case_path}: expected object")
        extra_key = "__unexpected_replay_lab_field__"
        while extra_key in target:
            extra_key = f"_{extra_key}"
        target[extra_key] = True
        try:
            validate(
                schema,
                schema,
                mutated,
                f"{example_name}#closed-object-{case_path}",
                schema_path,
                {schema_path: schema},
            )
        except ValidationError as exc:
            if "unexpected additional key" not in str(exc):
                raise ValidationError(
                    f"{example_name}: closed object check for {case_path} failed "
                    f"with unexpected error: {exc}"
                ) from exc
            continue
        raise ValidationError(f"{example_name}: schema accepted extra field in {case_path}")


def collect_numeric_bound_cases(
    schema: dict[str, Any],
    rule: dict[str, Any],
    value: Any,
    path: str,
    segments: list[str | int],
    schema_path: Path,
    cache: dict[Path, dict[str, Any]],
) -> list[tuple[str, list[str | int], str, int]]:
    if "$ref" in rule:
        target_schema, target_rule, target_path = resolve_ref(
            schema,
            schema_path,
            str(rule["$ref"]),
            cache,
        )
        return collect_numeric_bound_cases(
            target_schema,
            target_rule,
            value,
            path,
            segments,
            target_path,
            cache,
        )

    cases: list[tuple[str, list[str | int], str, int]] = []
    if isinstance(value, int) and not isinstance(value, bool):
        minimum = rule.get("minimum")
        maximum = rule.get("maximum")
        if isinstance(minimum, int):
            cases.append((path, list(segments), "expected >=", minimum - 1))
        if isinstance(maximum, int):
            cases.append((path, list(segments), "expected <=", maximum + 1))

    if isinstance(value, dict):
        properties = rule.get("properties", {})
        if not isinstance(properties, dict):
            raise ValidationError(f"{path}: properties must be an object")
        for key, child in properties.items():
            if key not in value:
                continue
            if not isinstance(child, dict):
                raise ValidationError(f"{path}.{key}: property schema must be an object")
            cases.extend(
                collect_numeric_bound_cases(
                    schema,
                    child,
                    value[key],
                    f"{path}.{key}",
                    [*segments, key],
                    schema_path,
                    cache,
                )
            )

    if isinstance(value, list) and "items" in rule:
        item_rule = rule["items"]
        if not isinstance(item_rule, dict):
            raise ValidationError(f"{path}: items schema must be an object")
        for index, item in enumerate(value):
            cases.extend(
                collect_numeric_bound_cases(
                    schema,
                    item_rule,
                    item,
                    f"{path}[{index}]",
                    [*segments, index],
                    schema_path,
                    cache,
                )
            )

    return cases


def validate_rejects_invalid_numeric_bounds(
    example_path: Path,
    schema_path: Path,
) -> None:
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

    cases = collect_numeric_bound_cases(
        schema,
        schema,
        example,
        example_name,
        [],
        schema_path,
        cache,
    )
    for case_path, segments, expected, invalid_value in cases:
        mutated = deepcopy(example)
        set_path_value(mutated, segments, invalid_value)
        try:
            validate(
                schema,
                schema,
                mutated,
                f"{example_name}#invalid-number-{case_path}",
                schema_path,
                {schema_path: schema},
            )
        except ValidationError as exc:
            if expected not in str(exc):
                raise ValidationError(
                    f"{example_name}: numeric bound check for {case_path} failed "
                    f"with unexpected error: {exc}"
                ) from exc
            continue
        raise ValidationError(f"{example_name}: schema accepted invalid number {case_path}")


def percent(numerator: int, denominator: int) -> int:
    if denominator == 0:
        return 100 if numerator == 0 else 0
    return numerator * 100 // denominator


def required_int(value: dict[str, Any], key: str, path: str) -> int:
    raw = value.get(key)
    if not isinstance(raw, int) or isinstance(raw, bool):
        raise ValidationError(f"{path}.{key}: expected integer, got {type_name(raw)}")
    return raw


def optional_int(value: dict[str, Any], key: str, path: str) -> int:
    if key not in value:
        return 0
    return required_int(value, key, path)


def replay_token_inputs(run: dict[str, Any]) -> int:
    usage = run.get("token_usage")
    if not isinstance(usage, dict):
        return 0
    return (
        optional_int(usage, "input_tokens", "token_usage")
        + optional_int(usage, "cache_creation_tokens", "token_usage")
        + optional_int(usage, "cache_read_tokens", "token_usage")
    )


def replay_token_outputs(run: dict[str, Any]) -> int:
    usage = run.get("token_usage")
    if not isinstance(usage, dict):
        return 0
    return optional_int(usage, "output_tokens", "token_usage")


def validate_optional_summary_int(
    summary: dict[str, Any],
    key: str,
    expected: int,
    path: str,
) -> None:
    if expected == 0 and key not in summary:
        return
    actual = required_int(summary, key, path)
    if actual != expected:
        raise ValidationError(f"{path}.{key}: expected {expected}, got {actual}")


def validate_eval_summary_consistency(
    example_path: Path,
    schema_path: Path,
    require_runs: bool,
) -> None:
    if schema_path.resolve().name != "eval-run.schema.json":
        return
    example = load_json(example_path)
    example_name = display_path(example_path)
    if not isinstance(example, dict):
        raise ValidationError(f"{example_name}: example root must be an object")

    runs = example.get("runs", [])
    if not isinstance(runs, list):
        raise ValidationError(f"{example_name}.runs: expected array")
    if not runs:
        if require_runs:
            raise ValidationError(f"{example_name}: eval example must include replay runs")
        return

    totals: dict[str, dict[str, int]] = {}
    for index, run in enumerate(runs):
        if not isinstance(run, dict):
            raise ValidationError(f"{example_name}.runs[{index}]: expected object")
        agent_name = run.get("agent")
        if not isinstance(agent_name, str) or not agent_name.strip():
            continue
        total = totals.setdefault(
            agent_name,
            {
                "runs": 0,
                "passed": 0,
                "failed": 0,
                "skipped": 0,
                "recall": 0,
                "precision": 0,
                "semantic_runs": 0,
                "semantic": 0,
                "duration_runs": 0,
                "duration": 0,
                "risk_score": 0,
                "input_tokens": 0,
                "output_tokens": 0,
            },
        )
        total["runs"] += 1
        status = run.get("status")
        if status == "passed":
            total["passed"] += 1
        elif status == "skipped":
            total["skipped"] += 1
        else:
            total["failed"] += 1

        metrics = run.get("metrics", {})
        if not isinstance(metrics, dict):
            raise ValidationError(f"{example_name}.runs[{index}].metrics: expected object")
        total["recall"] += required_int(metrics, "file_recall", f"{example_name}.runs[{index}].metrics")
        total["precision"] += required_int(metrics, "file_precision", f"{example_name}.runs[{index}].metrics")
        if metrics.get("semantic_available") is True:
            total["semantic_runs"] += 1
            total["semantic"] += optional_int(
                metrics,
                "semantic_similarity",
                f"{example_name}.runs[{index}].metrics",
            )

        duration = optional_int(run, "duration_ms", f"{example_name}.runs[{index}]")
        if duration > 0:
            total["duration_runs"] += 1
            total["duration"] += duration
        total["risk_score"] += required_int(metrics, "risk_score", f"{example_name}.runs[{index}].metrics")
        total["input_tokens"] += replay_token_inputs(run)
        total["output_tokens"] += replay_token_outputs(run)

    summaries = example.get("summaries", [])
    if not isinstance(summaries, list):
        raise ValidationError(f"{example_name}.summaries: expected array")
    by_agent: dict[str, dict[str, Any]] = {}
    for index, summary in enumerate(summaries):
        if not isinstance(summary, dict):
            raise ValidationError(f"{example_name}.summaries[{index}]: expected object")
        agent_name = summary.get("agent")
        if not isinstance(agent_name, str):
            raise ValidationError(f"{example_name}.summaries[{index}].agent: expected string")
        if agent_name in by_agent:
            raise ValidationError(f"{example_name}.summaries: duplicate agent {agent_name!r}")
        by_agent[agent_name] = summary

    if set(by_agent) != set(totals):
        raise ValidationError(
            f"{example_name}.summaries: agents {sorted(by_agent)} do not match runs {sorted(totals)}"
        )
    declared_agents = example.get("agents", [])
    if isinstance(declared_agents, list) and set(declared_agents) != set(totals):
        raise ValidationError(
            f"{example_name}.agents: agents {sorted(declared_agents)} do not match runs {sorted(totals)}"
        )

    for agent_name, total in totals.items():
        summary = by_agent[agent_name]
        path = f"{example_name}.summaries[{agent_name}]"
        expected = {
            "runs": total["runs"],
            "passed": total["passed"],
            "failed": total["failed"],
            "skipped": total["skipped"],
            "pass_rate": percent(total["passed"], total["runs"]),
            "avg_file_recall": total["recall"] // total["runs"],
            "avg_file_precision": total["precision"] // total["runs"],
            "risk_score": total["risk_score"],
            "avg_duration_ms": (
                total["duration"] // total["duration_runs"]
                if total["duration_runs"] > 0
                else 0
            ),
        }
        for key, value in expected.items():
            actual = required_int(summary, key, path)
            if actual != value:
                raise ValidationError(f"{path}.{key}: expected {value}, got {actual}")
        validate_optional_summary_int(
            summary,
            "semantic_runs",
            total["semantic_runs"],
            path,
        )
        validate_optional_summary_int(
            summary,
            "avg_semantic_similarity",
            (
                total["semantic"] // total["semantic_runs"]
                if total["semantic_runs"] > 0
                else 0
            ),
            path,
        )
        validate_optional_summary_int(summary, "input_tokens", total["input_tokens"], path)
        validate_optional_summary_int(summary, "output_tokens", total["output_tokens"], path)


def validate_rejects_eval_run_extra_field(
    example_path: Path,
    schema_path: Path,
    require_runs: bool,
) -> None:
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
        if require_runs:
            raise ValidationError(f"{example_name}: eval example must include a replay run")
        return
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


def validate_rejects_stale_eval_summary(example_path: Path, schema_path: Path) -> None:
    if schema_path.resolve().name != "eval-run.schema.json":
        return
    example = load_json(example_path)
    example_name = display_path(example_path)
    if not isinstance(example, dict):
        raise ValidationError(f"{example_name}: example root must be an object")
    runs = example.get("runs")
    summaries = example.get("summaries")
    if not runs or not isinstance(runs, list) or not summaries or not isinstance(summaries, list):
        return
    if not isinstance(summaries[0], dict):
        return
    mutated = dict(example)
    mutated_summaries = [dict(summary) if isinstance(summary, dict) else summary for summary in summaries]
    current = mutated_summaries[0].get("passed", 0)
    mutated_summaries[0]["passed"] = current + 1 if isinstance(current, int) else 1
    mutated["summaries"] = mutated_summaries

    with tempfile_json(example_path.name, mutated) as mutated_path:
        try:
            validate_eval_summary_consistency(mutated_path, schema_path, require_runs=False)
        except ValidationError:
            return
    raise ValidationError(f"{example_name}: validator accepted a stale eval summary")


class tempfile_json:
    def __init__(self, name: str, value: dict[str, Any]) -> None:
        self.name = name
        self.value = value
        self.path: Path | None = None

    def __enter__(self) -> Path:
        import tempfile

        handle = tempfile.NamedTemporaryFile(
            "w",
            encoding="utf-8",
            prefix=f"{self.name}.",
            suffix=".json",
            delete=False,
        )
        with handle:
            json.dump(self.value, handle)
        self.path = Path(handle.name)
        return self.path

    def __exit__(self, exc_type: Any, exc: Any, tb: Any) -> None:
        if self.path is not None:
            self.path.unlink(missing_ok=True)


def checked_pairs(args: list[str]) -> list[tuple[Path, Path, bool]]:
    if not args:
        return [
            (ROOT / "examples/replay-run.json", ROOT / "schemas/replay-run.schema.json", True),
            (ROOT / "examples/eval-run.json", ROOT / "schemas/eval-run.schema.json", True),
        ]
    pairs: list[tuple[Path, Path, bool]] = []
    remaining = list(args)
    while remaining:
        if len(remaining) < 3 or remaining[0] != "--check":
            raise ValidationError(
                "usage: validate-examples.py [--check <json> <schema>]..."
            )
        pairs.append((Path(remaining[1]), Path(remaining[2]), False))
        del remaining[:3]
    return pairs


def main() -> int:
    try:
        for example, schema, require_nested_examples in checked_pairs(sys.argv[1:]):
            validate_path(example, schema)
            validate_rejects_extra_field(example, schema)
            validate_rejects_closed_object_extra_fields(example, schema)
            validate_rejects_invalid_required_strings(example, schema, require_nested_examples)
            validate_rejects_invalid_file_array_items(example, schema, require_nested_examples)
            validate_rejects_invalid_date_times(example, schema, require_nested_examples)
            validate_date_time_order(example, schema)
            validate_rejects_inverted_date_times(example, schema, require_nested_examples)
            validate_rejects_duplicate_unique_arrays(example, schema, require_nested_examples)
            validate_rejects_invalid_numeric_bounds(example, schema)
            validate_eval_summary_consistency(example, schema, require_nested_examples)
            validate_rejects_eval_run_extra_field(example, schema, require_nested_examples)
            validate_rejects_stale_eval_summary(example, schema)
    except (OSError, json.JSONDecodeError, ValidationError) as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
