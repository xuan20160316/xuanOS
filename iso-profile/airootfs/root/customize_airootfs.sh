#!/usr/bin/env bash
set -euo pipefail

LC_ALL=C
LANG=C
export LC_ALL LANG

echo '==> xuan OS: customizing airootfs'

chmod 0700 /root
chmod 0755 /etc/audit 2>/dev/null || true
chmod 0755 /etc/audit/plugins.d 2>/dev/null || true
chmod 0755 /etc/selinux 2>/dev/null || true
chmod 0755 /etc/setroubleshoot 2>/dev/null || true
chmod 0755 /etc/setroubleshoot/plugins 2>/dev/null || true

sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL:ALL)\s\+ALL\)/\1/' /etc/sudoers
install -d -m 0750 /etc/sudoers.d
cat > /etc/sudoers.d/10-xuan-nopasswd-live <<'EOF'
xuan ALL=(ALL:ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/10-xuan-nopasswd-live

sed -i 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^#\(zh_CN\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen

cat > /etc/locale.conf <<'EOF'
LANG=zh_CN.UTF-8
LC_ADDRESS=zh_CN.UTF-8
LC_IDENTIFICATION=zh_CN.UTF-8
LC_MEASUREMENT=zh_CN.UTF-8
LC_MONETARY=zh_CN.UTF-8
LC_NAME=zh_CN.UTF-8
LC_NUMERIC=zh_CN.UTF-8
LC_PAPER=zh_CN.UTF-8
LC_TELEPHONE=zh_CN.UTF-8
LC_TIME=zh_CN.UTF-8
EOF

cat > /etc/vconsole.conf <<'EOF'
KEYMAP=us
FONT=eurlatgr
EOF

ln -sf /usr/share/zoneinfo/UTC /etc/localtime
cat > /etc/hostname <<'EOF'
xuanos-live
EOF
cat > /etc/hosts <<'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   xuanos-live.localdomain xuanos-live
EOF

systemd-sysusers /usr/lib/sysusers.d/xuanos-live.conf
for grp in wheel power audio video storage optical network lp scanner input docker; do
    groupadd -f "$grp"
    gpasswd -a xuan "$grp" >/dev/null
done
passwd -d xuan >/dev/null
passwd -l root >/dev/null
install -d -o 1000 -g 1000 -m 0700 /home/xuan

install -d -m 0755 /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux

systemctl enable systemd-timesyncd.service
systemctl enable NetworkManager.service
systemctl enable systemd-binfmt.service
systemctl enable systemd-hwdb-update.service
systemctl enable systemd-resolved.service
systemctl enable fstrim.timer
systemctl enable logrotate.timer
systemctl enable plocate-updatedb.timer 2>/dev/null || true
systemctl enable reflector.timer
systemctl enable sddm.service
systemctl enable cups.service
systemctl enable bluetooth.service
systemctl enable ufw.service
systemctl set-default graphical.target

ufw --force enable >/dev/null
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null

install -d /etc/xdg/reflector
cat > /etc/xdg/reflector/reflector.conf <<'EOF'
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 10
--sort rate
--age 12
EOF

fc-cache -f >/dev/null 2>&1 || true
gtk-update-icon-cache -f -t /usr/share/icons/breeze 2>/dev/null || true
gtk-update-icon-cache -f -t /usr/share/icons/breeze-dark 2>/dev/null || true
update-desktop-database -q /usr/share/applications 2>/dev/null || true
systemd-hwdb update
mandb --quiet 2>/dev/null || true

pacman -Rns --noconfirm "$(pacman -Qdtq 2>/dev/null || true)" 2>/dev/null || true
pacman -Scc --noconfirm >/dev/null 2>&1 || true
rm -rf /tmp/* /var/tmp/* /var/cache/pacman/pkg/* /var/lib/systemd/catalog/database
find /var/log -type f -exec truncate -s 0 {} \;
rm -f /etc/machine-id
: > /etc/machine-id

echo '==> xuan OS: airootfs customization complete'
