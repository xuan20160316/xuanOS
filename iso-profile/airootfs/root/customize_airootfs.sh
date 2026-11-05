#!/usr/bin/env bash
set -euo pipefail
trap 'echo "==> customization failed at line ${LINENO}" >&2' ERR

LC_ALL=C
LANG=C
export LC_ALL LANG

echo '==> xuan OS: customizing airootfs'

chmod 0700 /root
for d in /etc/audit /etc/audit/plugins.d /etc/selinux /etc/setroubleshoot /etc/setroubleshoot/plugins; do
    [ -d "$d" ] && chmod 0755 "$d"
done

if [ -f /etc/sudoers ]; then
    sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL:ALL)\s\+ALL\)/\1/' /etc/sudoers
fi
install -d -m 0750 /etc/sudoers.d
printf 'xuan ALL=(ALL:ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/10-xuan-nopasswd-live
chmod 0440 /etc/sudoers.d/10-xuan-nopasswd-live

sed -i 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^#\(zh_CN\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen || echo "==> locale-gen returned non-zero, continuing"

printf 'LANG=zh_CN.UTF-8\nLC_ADDRESS=zh_CN.UTF-8\nLC_IDENTIFICATION=zh_CN.UTF-8\nLC_MEASUREMENT=zh_CN.UTF-8\nLC_MONETARY=zh_CN.UTF-8\nLC_NAME=zh_CN.UTF-8\nLC_NUMERIC=zh_CN.UTF-8\nLC_PAPER=zh_CN.UTF-8\nLC_TELEPHONE=zh_CN.UTF-8\nLC_TIME=zh_CN.UTF-8\n' > /etc/locale.conf

printf 'KEYMAP=us\nFONT=eurlatgr\n' > /etc/vconsole.conf

ln -sf /usr/share/zoneinfo/UTC /etc/localtime
printf 'xuanos-live\n' > /etc/hostname
printf '127.0.0.1   localhost\n::1         localhost\n127.0.1.1   xuanos-live.localdomain xuanos-live\n' > /etc/hosts

systemd-sysusers /usr/lib/sysusers.d/xuanos-live.conf
id xuan >/dev/null

for grp in wheel power audio video storage optical network lp scanner input; do
    groupadd -f "$grp"
    gpasswd -a xuan "$grp" >/dev/null 2>&1 || true
done
groupadd -f docker
passwd -d xuan >/dev/null
passwd -l root >/dev/null || true
install -d -o 1000 -g 1000 -m 0700 /home/xuan

pacman-key --init || echo "==> pacman-key init skipped"
pacman-key --populate archlinux || echo "==> pacman-key populate skipped"

for unit in systemd-timesyncd.service NetworkManager.service systemd-binfmt.service systemd-resolved.service fstrim.timer logrotate.timer reflector.timer sddm.service cups.service bluetooth.service ufw.service; do
    systemctl enable "$unit" 2>/dev/null || echo "==> skipped enable $unit"
done
systemctl enable plocate-updatedb.timer 2>/dev/null || true
systemctl set-default graphical.target

ufw --force enable >/dev/null 2>&1 || echo "==> ufw enable skipped in chroot"

install -d /etc/xdg/reflector
printf -- '--save /etc/pacman.d/mirrorlist\n--protocol https\n--latest 10\n--sort rate\n--age 12\n' > /etc/xdg/reflector/reflector.conf

fc-cache -f >/dev/null 2>&1 || true
gtk-update-icon-cache -f -t /usr/share/icons/breeze 2>/dev/null || true
gtk-update-icon-cache -f -t /usr/share/icons/breeze-dark 2>/dev/null || true
update-desktop-database -q /usr/share/applications 2>/dev/null || true
systemd-hwdb update >/dev/null 2>&1 || true
mandb --quiet >/dev/null 2>&1 || true

pacman -Rns --noconfirm "$(pacman -Qdtq 2>/dev/null || true)" >/dev/null 2>&1 || true
pacman -Scc --noconfirm >/dev/null 2>&1 || true
rm -rf /tmp/* /var/tmp/* /var/cache/pacman/pkg/* /var/lib/systemd/catalog/database
find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null || true
rm -f /etc/machine-id
: > /etc/machine-id

echo '==> xuan OS: airootfs customization complete'
