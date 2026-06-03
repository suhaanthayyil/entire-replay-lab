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
checked example payloads.

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
      "runs": 3,
      "passed": 3,
      "pass_rate": 100,
      "avg_file_recall": 92,
      "avg_file_precision": 88,
      "avg_semantic_similarity": 81,
      "risk_score": 1,
      "avg_duration_ms": 134000
    }
  ],
  "runs": []
}
```

## Stability Rules

- New fields should be added to the schema, docs, and examples in the same
  change.
- `schema_version` changes only for breaking JSON changes.
- Large `diff` and `output` strings may be truncated.
- Truncation is always signaled with `diff_truncated` or `output_truncated`.
- Missing optional integrations use explicit false/empty values instead of
  failing the whole run.
