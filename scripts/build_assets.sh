#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY="$ROOT/overlays/rootfs"
WALLPAPER_SVG="$OVERLAY/usr/share/wallpapers/xuanos/xuanos-default.svg"
LOGO_SVG="$OVERLAY/usr/share/icons/xuanos/xuanos-logo.svg"
GRUB_DIR="$OVERLAY/usr/share/grub/themes/xuanos"
SDDM_DIR="$OVERLAY/usr/share/sddm/themes/xuanos"

die() { echo "error: $*" >&2; exit 1; }
for tool in rsvg-convert grub-mkfont fc-match; do
    command -v "$tool" >/dev/null || die "required tool not found: $tool"
done

echo '==> Rasterizing backgrounds'
rsvg-convert -w 1920 -h 1080 "$WALLPAPER_SVG" -o "$GRUB_DIR/background.png"
rsvg-convert -w 1920 -h 1080 "$WALLPAPER_SVG" -o "$SDDM_DIR/background.png"
cp "$LOGO_SVG" "$SDDM_DIR/xuanos-logo.svg"

echo '==> Resolving font files'
REGULAR="$(fc-match -f '%{file}' 'Inter:style=Regular')"
BOLD="$(fc-match -f '%{file}' 'Inter:style=Bold')"
[[ -n "$REGULAR" && -f "$REGULAR" ]] || die "Inter Regular font unavailable"
[[ -n "$BOLD" && -f "$BOLD" ]] || die "Inter Bold font unavailable"

echo '==> Generating GRUB pf2 fonts'
grub-mkfont -s 13 -o "$GRUB_DIR/xui_regular_13.pf2" "$REGULAR"
grub-mkfont -s 14 -o "$GRUB_DIR/xui_regular_14.pf2" "$REGULAR"
grub-mkfont -s 15 -o "$GRUB_DIR/xui_regular_15.pf2" "$REGULAR"
grub-mkfont -s 18 -o "$GRUB_DIR/xui_regular_18.pf2" "$REGULAR"
grub-mkfont -s 18 -o "$GRUB_DIR/xui_bold_18.pf2" "$BOLD"
grub-mkfont -s 24 -o "$GRUB_DIR/xui_bold_24.pf2" "$BOLD"
grub-mkfont -s 34 -o "$GRUB_DIR/xui_bold_34.pf2" "$BOLD"

echo '==> Assets ready'
