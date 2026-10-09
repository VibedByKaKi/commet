# VibedByKaKi/commet

Personal fork of [Commet](https://github.com/commetchat/commet). Work happens on [`dev`](https://github.com/VibedByKaKi/commet/tree/dev). [`main`](https://github.com/VibedByKaKi/commet/tree/main) tracks upstream.

Upstream does not accept generative-AI contributions, so changes here stay on this fork. They will not be opened as PRs upstream.

The upstream project README is still in [README.md](../README.md) at the repository root.

## Branches

| Branch | Role |
| --- | --- |
| `main` | Mirror of [commetchat/commet](https://github.com/commetchat/commet) `main` |
| `dev` | Default branch for fork-only enhancements |

Feature work branches from `dev` and merges back into `dev`.

## CI

The **build** workflow:

| Trigger | Platforms |
| --- | --- |
| Tag created | Windows, macOS, Linux, Android, Web |
| Push to a non-`dev` branch, PR, merge queue | Linux, Android |

Pushes to `dev` do not build. Tag a commit on `dev` when you want the full matrix.

APKs upload as single files (not wrapped in a zip). Windows, Linux, and Web builds are directories, so those stay zipped.

Linux artifacts vendor `libmpv` (and related runtime libs) into `lib/` and launch through a small wrapper so the binary does not need a system `libmpv2` package.

### macOS artifacts

Tag builds upload `commet-macos-<tag>.zip` (for example `commet-macos-0.1.0-dev.0.zip`). Unzipping yields a `commet.app` bundle. Builds are ad-hoc signed; after downloading, clear Gatekeeper quarantine before opening:

```bash
unzip commet-macos-0.1.0-dev.0.zip
xattr -cr commet.app
open commet.app
```

