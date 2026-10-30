#!/usr/bin/env bash
#
# run_tests.sh — static validation suite for the xuan OS source tree.
# Does not require root or a full Arch host; safe to run in CI.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0
checks=0

report() {
    checks=$((checks + 1))
    if [[ "$1" -eq 0 ]]; then
        echo "PASS: $2"
    else
        echo "FAIL: $2"
        failures=$((failures + 1))
    fi
}

echo '==> Bash syntax'
mapfile -t bash_scripts < <(find "$ROOT" -type f \( -name '*.sh' -o -name 'xuan-ctl' -o -name 'xuan-winrun' -o -name 'customize_airootfs.sh' -o -name 'profiledef.sh' \) -not -path '*/build/*')
for script in "${bash_scripts[@]}"; do
    bash -n "$script"
    report $? "syntax: ${script#"$ROOT"/}"
done

if command -v shellcheck >/dev/null; then
    echo '==> ShellCheck'
    shellcheck -x -S warning "${bash_scripts[@]}"
    report $? "shellcheck warnings"
else
    echo 'SKIP: shellcheck not installed'
fi

echo '==> Python syntax'
python3 -m py_compile "$ROOT/src/xuan-welcome/xuan_welcome.py"
report $? "python compile: xuan_welcome.py"

echo '==> YAML module configs'
if python3 -c 'import yaml' 2>/dev/null; then
    while IFS= read -r yaml_file; do
        python3 -c "import yaml,sys; list(yaml.safe_load_all(open(sys.argv[1])))" "$yaml_file"
        report $? "yaml: ${yaml_file#"$ROOT"/}"
    done < <(find "$ROOT/src/calamares-settings" -name '*.conf' -o -name '*.desc' | grep -v build || true)
else
    echo 'SKIP: PyYAML not installed'
fi

echo '==> Package manifest'
if [[ -f "$ROOT/iso-profile/packages.x86_64" ]]; then
    duplicates="$(grep -v '^#' "$ROOT/iso-profile/packages.x86_64" | grep -v '^$' | sort | uniq -d || true)"
    [[ -z "$duplicates" ]]
    report $? "no duplicate package entries"
    package_count="$(grep -vc '^#' "$ROOT/iso-profile/packages.x86_64" | grep -v '^$' || true)"
    echo "INFO: manifest contains $(grep -v '^#' "$ROOT/iso-profile/packages.x86_64" | grep -cv '^$') package lines"
fi

echo '==> Required files present'
required=(
    "iso-profile/profiledef.sh"
    "iso-profile/pacman.conf"
    "iso-profile/packages.x86_64"
    "iso-profile/airootfs/root/customize_airootfs.sh"
    "overlays/rootfs/usr/share/wallpapers/xuanos/xuanos-default.svg"
    "overlays/rootfs/usr/share/icons/xuanos/xuanos-logo.svg"
    "overlays/rootfs/usr/share/grub/themes/xuanos/theme.txt"
    "overlays/rootfs/usr/share/sddm/themes/xuanos/Main.qml"
    "src/xuan-ctl/xuan-ctl"
    "src/xuan-winrun/xuan-winrun"
    "src/xuan-welcome/xuan_welcome.py"
    "LICENSE"
    "README.md"
)
for rel in "${required[@]}"; do
    [[ -f "$ROOT/$rel" ]]
    report $? "exists: $rel"
done

echo '==> SVG well-formed'
if command -v xmllint >/dev/null; then
    while IFS= read -r svg; do
        xmllint --noout "$svg"
        report $? "xml: ${svg#"$ROOT"/}"
    done < <(find "$ROOT/overlays" -name '*.svg')
else
    echo 'SKIP: xmllint not installed'
fi

echo
echo "Ran ${checks} checks with ${failures} failure(s)."
if (( failures > 0 )); then
    exit 1
fi
echo "All static checks passed."
