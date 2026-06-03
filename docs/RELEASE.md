# Release Process

Replay Lab is a prototype repo, but releases should still be reproducible.

## Release Check

Run the release check before tagging any prototype release:

```bash
./scripts/release-check.sh
```

It verifies the repository package, example schemas, patched CLI build,
Replay/Eval command surface, saved report fixtures, release-note consistency,
pinned reproducibility metadata, patch manifest, and fresh-clone patch tests
without launching a live coding agent.

## Before Tagging

For a machine-specific live check against a repo with checkpoints, also run:

```bash
./scripts/smoke.sh /path/to/entire-enabled/repo
```

Before tagging, also confirm that the matching release note exists, for example:

- `docs/releases/v0.1.2.md`

## Tagging

Use semantic-ish prototype tags:

```bash
git tag v0.1.0
git push origin v0.1.0
```

Then create the GitHub release using the matching file in `docs/releases/`.

After publishing, verify the remote release state:

```bash
./scripts/verify-release-state.sh
```

This checks that release-note files, local tags, GitHub releases, and the latest
origin tag all agree, and that the latest release tag points at the current
commit. It also checks that the latest GitHub release body matches the checked-in
release note.

## What To Include In Release Notes

- what pain the release solves
- what commands are available
- how to build and test
- what has been verified
- known limitations
