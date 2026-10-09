#!/usr/bin/env bash
# flutter_webrtc (hkdf) pins WebRTC-SDK 144.7559.04 while livekit_client pins
# 144.7559.01. CocoaPods cannot resolve both exact versions. Prefer the
# flutter_webrtc pin and drop any stale Podfile.lock snapshot.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
rm -f macos/Podfile.lock

python3 - <<'PY'
import json
import pathlib
import re
import sys
import urllib.parse

cfg_path = pathlib.Path(".dart_tool/package_config.json")
if not cfg_path.is_file():
    print("error: .dart_tool/package_config.json missing; run flutter pub get first", file=sys.stderr)
    sys.exit(1)

cfg = json.loads(cfg_path.read_text())
cfg_dir = cfg_path.parent
old = "WebRTC-SDK', '144.7559.01'"
new = "WebRTC-SDK', '144.7559.04'"
podspecs = []

for pkg in cfg.get("packages", []):
    if pkg.get("name") != "livekit_client":
        continue
    root_uri = pkg.get("rootUri", "")
    if root_uri.startswith("file:"):
        root = pathlib.Path(urllib.parse.urlparse(root_uri).path)
    else:
        root = (cfg_dir / root_uri).resolve()
    for rel in ("macos/livekit_client.podspec", "ios/livekit_client.podspec"):
        podspec = root / rel
        if podspec.is_file():
            podspecs.append(podspec)

if not podspecs:
    print("error: livekit_client podspec not found via package_config.json", file=sys.stderr)
    for pkg in cfg.get("packages", []):
        if pkg.get("name") == "livekit_client":
            print(pkg, file=sys.stderr)
    sys.exit(1)

patched = 0
for podspec in podspecs:
    text = podspec.read_text()
    if old not in text:
        print(f"No 144.7559.01 pin in {podspec}")
        for line in text.splitlines():
            if "WebRTC-SDK" in line:
                print(f"  {line.strip()}")
        continue
    podspec.write_text(text.replace(old, new))
    print(f"Patched {podspec}")
    patched += 1

if patched == 0 and any(old in p.read_text() for p in podspecs):
    print("error: livekit_client still pins WebRTC-SDK 144.7559.01", file=sys.stderr)
    sys.exit(1)

if patched == 0:
    # Confirm every podspec already matches flutter_webrtc.
    for podspec in podspecs:
        pins = re.findall(r"WebRTC-SDK',\s*'([^']+)'", podspec.read_text())
        if any(pin != "144.7559.04" for pin in pins):
            print(f"error: unexpected WebRTC-SDK pins in {podspec}: {pins}", file=sys.stderr)
            sys.exit(1)
    print("livekit_client WebRTC-SDK pins already aligned")
PY
