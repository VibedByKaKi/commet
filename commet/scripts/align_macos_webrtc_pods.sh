#!/usr/bin/env bash
# flutter_webrtc (hkdf) pins WebRTC-SDK 144.7559.04 while livekit_client pins
# 144.7559.01. CocoaPods cannot resolve both exact versions. Prefer the
# flutter_webrtc pin and drop the stale Podfile.lock snapshot.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
rm -f "$ROOT/macos/Podfile.lock"

patched=0
while IFS= read -r -d '' podspec; do
  if grep -q "WebRTC-SDK', '144.7559.01'" "$podspec"; then
    sed -i.bak "s/WebRTC-SDK', '144.7559.01'/WebRTC-SDK', '144.7559.04'/" "$podspec"
    rm -f "${podspec}.bak"
    echo "Patched $podspec"
    patched=$((patched + 1))
  fi
done < <(find "${PUB_CACHE:-$HOME/.pub-cache}" -path '*livekit_client*/macos/livekit_client.podspec' -print0 2>/dev/null)

if [[ "$patched" -eq 0 ]]; then
  echo "warning: no livekit_client macOS podspec with WebRTC-SDK 144.7559.01 found to patch" >&2
fi
