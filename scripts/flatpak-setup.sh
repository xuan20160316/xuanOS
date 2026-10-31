#!/usr/bin/env bash
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

if (( EUID != 0 )); then
    echo "System-wide setup needs root, requesting sudo..."
    exec sudo -E "$0" "$@"
fi

if ! command -v flatpak >/dev/null; then
    die "flatpak is not installed. Run: pacman -S flatpak"
fi

echo '==> Adding Flathub remote (idempotent)'
flatpak remote-add --if-not-exists --system flathub \
    https://flathub.org/repo/flathub.flatpakrepo

echo '==> Refreshing AppStream metadata'
flatpak update --appstream --system --noninteractive || true

echo '==> Flatpak/Flathub is ready. Search with: flatpak search <name>'
