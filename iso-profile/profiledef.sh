#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

iso_name="xuanos"
iso_label="XUANOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m%d)"
iso_publisher="xuan OS Project <https://github.com/xuan20160316/xuanOS>"
iso_application="xuan OS Live/Install ISO"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')

file_permissions=(
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/lib/sysusers.d/xuanos-live.conf"]="0:0:644"
)
