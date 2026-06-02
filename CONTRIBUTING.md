# Contributing

Replay Lab currently ships as a standalone prototype repo plus a patch against a
known Entire CLI base commit.

## Development Loop

1. Make implementation changes in an Entire CLI checkout.
2. Run the Replay Lab CLI tests there.
3. Refresh the patch:

   ```bash
   ENTIRE_CLI_SOURCE=/path/to/cli-replay-lab ./scripts/refresh-patch.sh
   ```

4. Verify this repo:

   ```bash
   ./scripts/verify-repo.sh
   ./scripts/check-patch.sh
   ./scripts/build-cli.sh
   ```

5. Update docs/examples if CLI behavior changed.

## Expectations

- Keep the patch MIT-compatible.
- Do not add network calls outside normal agent execution.
- Keep replay runs isolated from the user's current worktree.
- Keep JSON changes additive unless `schema_version` changes.
- Document any behavior that can mutate local state.
