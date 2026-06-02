# Reproducibility

Replay Lab is distributed as a patch repo, so reproducibility depends on keeping
the upstream Entire CLI base commit, patch path, docs, and helper scripts in
sync.

## Pinned Inputs

The shared defaults live in `scripts/replay-lab-env.sh`:

```text
ENTIRE_CLI_REPO=https://github.com/entireio/cli.git
ENTIRE_CLI_REF=e858fb537e70b8008a10f712cb73588cb67aacf2
ENTIRE_REPLAY_PATCH=patches/entire-replay-lab.patch
```

`build-cli.sh`, `check-patch.sh`, and `refresh-patch.sh` all source that file.
Environment variables can still override the repo, ref, or patch for local
experiments.

## Verify The Pin

Run:

```bash
./scripts/verify-reproducibility.sh
```

This checks:

- the pinned repo/ref/patch values are non-empty
- the patch file exists
- the default ref is a full commit hash
- build, patch-check, and patch-refresh scripts source the shared inputs
- docs mention the same pinned base commit
- the current patch SHA-256 can be printed for audit notes

## Refreshing The Patch

When regenerating the patch, `refresh-patch.sh` defaults to diffing against the
pinned `ENTIRE_CLI_REF`, not the moving `origin/main` branch:

```bash
ENTIRE_CLI_SOURCE=/path/to/cli-replay-lab ./scripts/refresh-patch.sh
```

That keeps the patch anchored to the same base that CI and release checks build
against.
