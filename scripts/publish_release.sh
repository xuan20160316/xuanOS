#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE="$ROOT/update-site"
RELEASES="$SITE/releases"

die() { echo "error: $*" >&2; exit 1; }

[[ $# -ge 2 ]] || die "usage: publish_release.sh <iso> <version> [notes.txt]"
ISO_SOURCE="$1"
VERSION="$2"
NOTES_FILE="${3:-}"

[[ -f "$ISO_SOURCE" ]] || die "ISO not found: $ISO_SOURCE"
command -v python3 >/dev/null || die "python3 is required"

ISO_NAME="xuanos-${VERSION}-x86_64.iso"
echo "==> Computing SHA-256 (this can take a minute)"
SHA="$(sha256sum "$ISO_SOURCE" | awk '{print $1}')"
SIZE="$(stat -c %s "$ISO_SOURCE")"

echo "==> Copying ISO into release directory"
install -d "$RELEASES"
cp "$ISO_SOURCE" "$RELEASES/$ISO_NAME"
echo "$SHA  $ISO_NAME" > "$RELEASES/SHA256SUMS.txt"

echo "==> Updating manifest.json"
export MANIFEST_PATH="$SITE/manifest.json"
ISO_NAME="$ISO_NAME" SHA="$SHA" SIZE="$SIZE" VERSION="$VERSION" \
NOTES_FILE="$NOTES_FILE" python3 <<'PY'
import json
import os
from datetime import datetime, timezone, timedelta
from pathlib import Path

manifest_path = Path(os.environ["MANIFEST_PATH"])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
notes = []
if os.environ.get("NOTES_FILE"):
    notes = [
        line.strip()
        for line in Path(os.environ["NOTES_FILE"]).read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
if not notes:
    notes = manifest["latest"].get("release_notes", [])

previous = manifest["latest"]
history = manifest.setdefault("history", [])
history.insert(0, {
    "version": previous["version"],
    "release_date": previous["release_date"],
    "notes": previous.get("release_notes", []),
})

today = datetime.now(timezone(timedelta(hours=8))).date().isoformat()
manifest["generated_at"] = datetime.now(
    timezone(timedelta(hours=8))
).replace(microsecond=0).isoformat()
manifest["latest"] = {
    "version": os.environ["VERSION"],
    "release_date": today,
    "min_client_version": "1.0.0",
    "iso": {
        "filename": os.environ["ISO_NAME"],
        "url": f"releases/{os.environ['ISO_NAME']}",
        "size": int(os.environ["SIZE"]),
        "sha256": os.environ["SHA"],
    },
    "package_update": {
        "method": "pacman",
        "command": "xuan-ctl update",
        "requires_reboot": False,
    },
    "release_notes": notes,
}
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)
print("manifest updated")
PY

echo "==> Release ${VERSION} published to update site"
echo "    Next: deploy update-site (EdgeOne Pages) so clients see the new version."
