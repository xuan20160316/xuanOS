#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$ROOT/build/work"
OUT_DIR="$ROOT/build/out"

die() { echo "error: $*" >&2; exit 1; }

if (( EUID != 0 )); then
    echo "Build requires root for pacstrap/mkarchiso, invoking sudo..."
    exec sudo -E "$0" "$@"
fi

command -v mkarchiso >/dev/null || die "mkarchiso missing. Install it with: pacman -S archiso"
command -v rsync >/dev/null || die "rsync missing. Install it with: pacman -S rsync"
[[ -d "$ROOT/iso-profile" ]] || die "iso-profile directory not found"

case "${1:-build}" in
    clean)
        echo "==> Removing build artifacts"
        rm -rf "$WORK_DIR" "$OUT_DIR"
        echo "==> Done"
        exit 0
        ;;
    build) ;;
    *) die "Usage: ./build.sh [build|clean]" ;;
esac

mkdir -p "$WORK_DIR" "$OUT_DIR"

"$ROOT/scripts/build_assets.sh"
"$ROOT/scripts/apply_overlays.sh"

echo "==> Running mkarchiso"
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$ROOT/iso-profile"

echo "==> Generating checksums"
(cd "$OUT_DIR" && sha256sum -- *.iso > SHA256SUMS.txt)

echo "==> Build complete. Artifacts:"
ls -lh "$OUT_DIR"
