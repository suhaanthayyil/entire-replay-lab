# JSON Shape

The prototype writes stable JSON with `schema_version: 1`.

Machine-readable schema files live in:

```text
schemas/replay-run.schema.json
schemas/eval-run.schema.json
```

Validate the example payloads against those schemas with:

```bash
python3 ./scripts/validate-examples.py
```

The validator is intentionally dependency-free and supports the JSON Schema
features used by this repo, including `additionalProperties: false` for the
checked example payloads, local cross-schema `$ref` links, and eval summary
totals derived from embedded replay runs.

## ReplayRun

```json
{
  "schema_version": 1,
  "id": "rpl_7a1d4c9e",
  "spec": {
    "checkpoint_id": "9a91ce5c55f2",
    "session_id": "019e6ba4",
    "prompt": "Update validate_token to support issuer checks.",
    "target_commit": "2f9c481",
    "base_commit": "a77cd65",
    "files_touched": ["src/auth.py"],
    "original_agent": "codex",
    "original_model": "gpt-5.5"
  },
  "agent": "claude-code",
  "status": "passed",
  "changed_files": ["src/auth.py"],
  "diff_truncated": false,
  "test": {
    "status": "passed",
    "command": "python3 -m pytest",
    "duration_ms": 4120
  },
  "metrics": {
    "file_precision": 100,
    "file_recall": 100,
    "file_overlap": 1,
    "risk_score": 0,
    "semantic_available": true,
    "semantic_similarity": 86
  }
}
```

## ReplayEvalRun

```json
{
  "schema_version": 1,
  "id": "evl_a12c0f44",
  "agents": ["claude-code", "codex"],
  "summaries": [
    {
      "agent": "claude-code",
      "runs": 1,
      "passed": 1,
      "failed": 0,
      "skipped": 0,
      "pass_rate": 100,
      "avg_file_recall": 100,
      "avg_file_precision": 100,
      "risk_score": 0,
      "avg_duration_ms": 134000
    }
  ],
  "runs": [
    {
      "schema_version": 1,
      "id": "rpl_7a1d4c9e",
      "spec": {
        "checkpoint_id": "9a91ce5c55f2",
        "prompt": "Update validate_token to support issuer checks.",
        "target_commit": "2f9c481",
        "base_commit": "a77cd65",
        "files_touched": ["src/auth.py"]
      },
      "agent": "claude-code",
      "status": "passed",
      "changed_files": ["src/auth.py"],
      "test": {
        "status": "passed"
      },
      "metrics": {
        "file_precision": 100,
        "file_recall": 100,
        "file_overlap": 1,
        "risk_score": 0,
        "semantic_available": true
      }
    }
  ]
}
```

`ReplayEvalRun.runs[]` uses the same schema contract as a saved `ReplayRun`.
Example eval summaries are also checked against the embedded runs so stale
counts, rates, averages, risk scores, durations, or token totals fail
validation. When `--agent all` is used, `agents` may include every built-in
Entire coder. Pi appears as a skipped run until a safe non-interactive launch
contract exists.

## Stability Rules

- New fields should be added to the schema, docs, and examples in the same
  change.
- `schema_version` changes only for breaking JSON changes.
- Large `diff` and `output` strings may be truncated.
- Truncation is always signaled with `diff_truncated` or `output_truncated`.
- Failed test commands may include `test.error` with the launch, cancellation,
  or timeout cause.
- `changed_files` remains an array, including when diff inspection fails and a
  warning is recorded.
- Missing optional integrations use explicit false/empty values instead of
  failing the whole run.
