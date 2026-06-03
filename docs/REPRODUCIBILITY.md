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
ENTIRE_REPLAY_PATCH_SHA256=ca385c115a2f8704a88879d3a0b4f9d852201c5505332d34653bb03bd1adf030
```

`build-cli.sh`, `check-patch.sh`, and `refresh-patch.sh` all source that file.
Environment variables can still override the repo, ref, or patch for local
experiments. Set `ENTIRE_REPLAY_PATCH_SHA256=` for intentional local patch
experiments that should not use the pinned hash.

## Verify The Pin

Run:

```bash
./scripts/verify-reproducibility.sh
```

This checks:

- the pinned repo/ref/patch values are non-empty
- the patch file exists
- the default ref is a full commit hash
- the patch content matches the pinned SHA-256
- build, patch-check, and patch-refresh scripts source the shared inputs
- docs mention the same pinned base commit
- the current and expected patch SHA-256 are printed for audit notes

## Refreshing The Patch

When regenerating the patch, `refresh-patch.sh` defaults to diffing against the
pinned `ENTIRE_CLI_REF`, not the moving `origin/main` branch:

```bash
ENTIRE_CLI_SOURCE=/path/to/cli-replay-lab ./scripts/refresh-patch.sh
```

That keeps the patch anchored to the same base that CI and release checks build
against.
