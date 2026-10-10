#!/usr/bin/env bash
# Copy libmpv, keybinder, and every non-host dependency they need into the
# Flutter Linux bundle's lib/ directory. Wrap the binary so LD_LIBRARY_PATH
# prefers those libs (bundled .so files rarely have $ORIGIN rpath).
set -euo pipefail

BUNDLE="${1:?usage: bundle_linux_runtime_libs.sh <bundle-dir>}"
BIN="$BUNDLE/commet"
LIBDIR="$BUNDLE/lib"

if [[ ! -x "$BIN" ]]; then
  echo "error: missing executable $BIN" >&2
  exit 1
fi
mkdir -p "$LIBDIR"

# Seed only these from the main binary; then pull *all* of their deps that the
# host desktop stack is not expected to provide.
is_seed_lib() {
  case "$1" in
    libmpv.so*|libkeybinder*) return 0 ;;
    *) return 1 ;;
  esac
}

# Libraries every typical Linux desktop already has. Keep this list tight so
# uncommon deps (libXpresent, ffmpeg internals, etc.) still get vendored.
is_host_provided() {
  case "$1" in
    linux-vdso.so.*|ld-linux*.so.*|libc.so.*|libm.so.*|libdl.so.*|libpthread.so.*|librt.so.*|libresolv.so.*|libutil.so.*) return 0 ;;
    libgcc_s.so.*|libstdc++.so.*|libgomp.so.*|libatomic.so.*) return 0 ;;
    libgtk-*.so.*|libgdk-*.so.*|libglib-*.so.*|libgobject-*.so.*|libgio-*.so.*|libgmodule-*.so.*) return 0 ;;
    libpango*.so.*|libcairo*.so.*|libatk*.so.*|libharfbuzz.so.*|libgdk_pixbuf*.so.*|libepoxy.so.*) return 0 ;;
    libfontconfig.so.*|libfreetype.so.*|libfribidi.so.*|libthai.so.*|libdatrie.so.*|libpixman*.so.*|libgraphite2.so.*) return 0 ;;
    libz.so.*|libpng*.so.*|libjpeg*.so.*|libwebp*.so.*|libtiff*.so.*) return 0 ;;
    # Common X11 / Wayland — but NOT libXpresent and other uncommon extensions.
    libX11.so.*|libXext.so.*|libXrender.so.*|libXfixes.so.*|libXcursor.so.*|libXdamage.so.*) return 0 ;;
    libXcomposite.so.*|libXrandr.so.*|libXinerama.so.*|libXi.so.*|libXtst.so.*|libXau.so.*|libXdmcp.so.*) return 0 ;;
    libxcb.so.*|libxcb-*.so.*|libwayland-client.so.*|libwayland-cursor.so.*|libwayland-egl.so.*|libxkbcommon.so.*) return 0 ;;
    libsystemd.so.*|libdbus-*.so.*|libselinux.so.*|libmount.so.*|libblkid.so.*|libuuid.so.*|libpcre*.so.*|libffi.so.*) return 0 ;;
    libwebkit*.so.*|libjavascriptcore*.so.*|libsoup*.so.*) return 0 ;;
    libEGL.so.*|libGL.so.*|libGLdispatch.so.*|libGLX.so.*|libOpenGL.so.*) return 0 ;;
    *) return 1 ;;
  esac
}

declare -A SEEN=()
bundled_bases=()
queue=()

enqueue_libs_from() {
  local target="$1"
  local mode="$2" # seed | deps
  local lib base
  while read -r lib; do
    [[ -n "$lib" && -f "$lib" ]] || continue
    base="$(basename "$lib")"
    [[ -n "${SEEN[$base]:-}" ]] && continue
    if [[ "$mode" == "seed" ]]; then
      is_seed_lib "$base" || continue
    else
      is_host_provided "$base" && continue
    fi
    queue+=("$lib")
  done < <(ldd "$target" | awk '/=> \// {print $3}')
}

enqueue_libs_from "$BIN" seed

i=0
while [[ "$i" -lt "${#queue[@]}" ]]; do
  lib="${queue[$i]}"
  i=$((i + 1))
  base="$(basename "$lib")"
  [[ -n "${SEEN[$base]:-}" ]] && continue
  SEEN[$base]=1
  cp -L "$lib" "$LIBDIR/$base"
  bundled_bases+=("$base")
  echo "Bundled $base"
  enqueue_libs_from "$LIBDIR/$base" deps
done

if [[ ! -f "$LIBDIR/libmpv.so.2" ]]; then
  echo "error: failed to bundle libmpv.so.2" >&2
  exit 1
fi
if [[ ! -f "$LIBDIR/libXpresent.so.1" ]]; then
  echo "error: failed to bundle libXpresent.so.1 (required by libmpv)" >&2
  exit 1
fi

# Only verify libs we vendored — not Flutter plugin .so files already in lib/.
missing=0
for base in "${bundled_bases[@]}"; do
  lib="$LIBDIR/$base"
  while read -r line; do
    if [[ "$line" == *"not found"* ]]; then
      echo "error: unresolved dependency for $base: $line" >&2
      missing=1
      continue
    fi
    dep="$(awk '/=> \// {print $3}' <<<"$line")"
    [[ -n "$dep" && -f "$dep" ]] || continue
    depbase="$(basename "$dep")"
    is_host_provided "$depbase" && continue
    if [[ ! -f "$LIBDIR/$depbase" ]]; then
      echo "error: $base needs $depbase but it was not bundled" >&2
      missing=1
    fi
  done < <(ldd "$lib")
done
if [[ "$missing" -ne 0 ]]; then
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
echo "Bundled ${#bundled_bases[@]} libraries"
