#!/usr/bin/env bash
#
# apply_overlays.sh — stage overlays and original sources into the
# archiso airootfs so mkarchiso can squash them into the image.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AIROOTFS="$ROOT/iso-profile/airootfs"

echo '==> Syncing root filesystem overlay'
rsync -a "$ROOT/overlays/rootfs/" "$AIROOTFS/"

echo '==> Installing xuan OS tools'
install -Dm755 "$ROOT/src/xuan-ctl/xuan-ctl" "$AIROOTFS/usr/bin/xuan-ctl"
install -Dm755 "$ROOT/src/xuan-winrun/xuan-winrun" "$AIROOTFS/usr/bin/xuan-winrun"
install -Dm755 "$ROOT/src/xuan-welcome/xuan_welcome.py" "$AIROOTFS/usr/bin/xuan-welcome"

echo '==> Installing Calamares configuration'
install -Dm644 "$ROOT/src/calamares-settings/settings.conf" "$AIROOTFS/etc/calamares/settings.conf"
for module_conf in "$ROOT"/src/calamares-settings/modules/*.conf; do
    install -Dm644 "$module_conf" "$AIROOTFS/etc/calamares/modules/$(basename "$module_conf")"
done
install -d "$AIROOTFS/usr/share/calamares/branding"
rm -rf "$AIROOTFS/usr/share/calamares/branding/xuanos"
cp -a "$ROOT/src/calamares-settings/branding/xuanos" "$AIROOTFS/usr/share/calamares/branding/"

echo '==> Overlay stage complete'
