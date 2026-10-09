#!/usr/bin/env bash
# Copy libmpv, keybinder, and their uncommon deps into the Flutter Linux
# bundle's lib/ directory, and wrap the binary so those libs are found via
# LD_LIBRARY_PATH (bundled .so files rarely have $ORIGIN rpath).
set -euo pipefail

BUNDLE="${1:?usage: bundle_linux_runtime_libs.sh <bundle-dir>}"
BIN="$BUNDLE/commet"
LIBDIR="$BUNDLE/lib"

if [[ ! -x "$BIN" ]]; then
  echo "error: missing executable $BIN" >&2
  exit 1
fi
mkdir -p "$LIBDIR"

should_bundle() {
  case "$1" in
    libmpv.so*|libkeybinder*) return 0 ;;
    libavutil.so*|libavcodec.so*|libavformat.so*|libavfilter.so*|libavdevice.so*) return 0 ;;
    libswresample.so*|libswscale.so*|libpostproc.so*) return 0 ;;
    libass.so*|libplacebo.so*|libshaderc*|libmujs*|libbluray*|libdvd*|librubberband*) return 0 ;;
    libsamplerate.so*|libsndio.so*|libchromaprint*|libdovi*|libSvtAv1*|libaom.so*|libdav1d.so*) return 0 ;;
    libvpx.so*|libx264.so*|libx265.so*|libmp3lame.so*|libopus.so*|libvorbis*|libogg.so*) return 0 ;;
    libsoxr.so*|libspeex.so*|libOpenCL.so*|libnuma.so*|libasyncns.so*|libpulse*|libsndfile.so*) return 0 ;;
    libFLAC.so*|libmpg123.so*|libtwolame.so*|libssh.so*|libgme.so*|libopenmpt.so*|libbs2b.so*) return 0 ;;
    liblilv*|libsratom*|libserd*|libsord*|libmysofa*|libvidstab*|libzimg.so*|libmfx*|libigdgmm*) return 0 ;;
    libdrm.so*|libva.so*|libva-drm*|libva-x11*|libvdpau.so*|libXv.so*|libSPIRV*|libglslang*) return 0 ;;
    libshaderc_shared.so*|libwayland-server.so*|libudfread.so*|libnorm.so*|librist.so*|libsrt*.so*) return 0 ;;
    libaribb24.so*|libcodec2.so*|libgsm.so*|libjxl.so*|libopenjp2.so*|librav1e.so*|libxvidcore.so*) return 0 ;;
    *) return 1 ;;
  esac
}

declare -A SEEN=()
queue=()

enqueue_from() {
  local target="$1"
  local lib base
  while read -r lib; do
    [[ -n "$lib" && -f "$lib" ]] || continue
    base="$(basename "$lib")"
    should_bundle "$base" || continue
    [[ -n "${SEEN[$base]:-}" ]] && continue
    queue+=("$lib")
  done < <(ldd "$target" | awk '/=> \// {print $3}')
}

enqueue_from "$BIN"

i=0
while [[ "$i" -lt "${#queue[@]}" ]]; do
  lib="${queue[$i]}"
  i=$((i + 1))
  base="$(basename "$lib")"
  [[ -n "${SEEN[$base]:-}" ]] && continue
  SEEN[$base]=1
  cp -L "$lib" "$LIBDIR/$base"
  echo "Bundled $base"
  enqueue_from "$LIBDIR/$base"
done

if [[ ! -f "$LIBDIR/libmpv.so.2" ]]; then
  echo "error: failed to bundle libmpv.so.2" >&2
  exit 1
fi

if [[ -f "$BUNDLE/commet.bin" ]]; then
  echo "error: $BUNDLE/commet.bin already exists" >&2
  exit 1
fi

mv "$BIN" "$BUNDLE/commet.bin"
cat >"$BIN" <<'EOF'
#!/usr/bin/env bash
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="$HERE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$HERE/commet.bin" "$@"
EOF
chmod +x "$BIN"

echo "Wrapped launcher at $BIN"
