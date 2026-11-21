# VibedByKaKi/commet

Matrix client for Android, Linux, Windows, and macOS. Fork of [Commet](https://github.com/commetchat/commet).

The upstream project README stays in [README.md](../README.md) at the repository root.

| [![](assets/get-it-on-github.png)](https://github.com/VibedByKaKi/commet/releases/tag/latest) | [![](assets/badge_obtainium.png)](https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%257B%2522id%2522%253A%2522chat.halley.halleyapp%2522%252C%2522url%2522%253A%2522https%253A%252F%252Fgithub.com%252FVibedByKaKi%252Fcommet%2522%252C%2522author%2522%253A%2522VibedByKaKi%2522%252C%2522name%2522%253A%2522Halley%2522%252C%2522preferredApkIndex%2522%253A0%252C%2522additionalSettings%2522%253A%2522%257B%255C%2522includePrereleases%255C%2522%253A%2520true%252C%2520%255C%2522fallbackToOlderReleases%255C%2522%253A%2520true%252C%2520%255C%2522apkFilterRegEx%255C%2522%253A%2520%255C%2522.%252A%255C%255C%255C%255C.apk%2524%255C%2522%252C%2520%255C%2522releaseDateAsVersion%255C%2522%253A%2520true%257D%2522%257D) |
| --- | --- |

## Downloads

Rolling builds are on the [`latest`](https://github.com/VibedByKaKi/commet/releases/tag/latest) prerelease (refreshed from successful CI; a platform is omitted if that job failed):

| Platform | Download |
| --- | --- |
| Android (arm64) | [Halley.apk](https://github.com/VibedByKaKi/commet/releases/download/latest/Halley.apk) |
| Linux (x64) | [Halley-linux.zip](https://github.com/VibedByKaKi/commet/releases/download/latest/Halley-linux.zip) |
| macOS | [Halley-macos.zip](https://github.com/VibedByKaKi/commet/releases/download/latest/Halley-macos.zip) |

Linux: unzip, then run `./commet`. macOS: unzip and open `commet.app` (ad-hoc signed).

In Obtainium, keep **Include pre-releases** and **Use release date as version** on if you add the repo by hand, because the tag never changes.

Upstream does not accept generative-AI contributions, so changes here stay on this fork.

## Branches

| Branch | Role |
| --- | --- |
| `main` | Mirror of [commetchat/commet](https://github.com/commetchat/commet) `main` |
| `dev` | Default branch for fork-only enhancements |

Feature work branches from `dev` and merges back into `dev`.

## What this fork changes

- Ships as **Halley** (`chat.halley.halleyapp`) with fork About branding.
- Home visibility toggles under Appearance → Halley Options (hide recent activity / rooms on Home; show rooms in the Home sidebar below Direct messages, with DM-style previews).
- Signed release Android APKs; Check for updates points at the `latest` prerelease.
- macOS CI keeps file-access entitlements when ad-hoc signing so attachments work.

## CI

- **build** — signed Android / Linux / macOS / web artifacts on non-`dev` pushes (path-filtered), tags, and manual dispatch. A final `publish-latest` job replaces the [`latest`](https://github.com/VibedByKaKi/commet/releases/tag/latest) prerelease with whichever of `Halley.apk` / `Halley-linux.zip` / `Halley-macos.zip` succeeded that run (other platforms failing does not block publishing).
- **integration-test** / **static-analysis** / **benchmark** — same push triggers; each uses cancel-in-progress so only the newest SHA keeps running.

Pushes to `dev` do not build. Push a feature branch, tag a commit on `dev`, or use workflow dispatch when you want artifacts / a refreshed `latest` release.
