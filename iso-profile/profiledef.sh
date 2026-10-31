#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

iso_name="xuanos"
iso_label="XUANOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m%d)"
iso_publisher="xuan OS Project <https://github.com/xuanos/xuanos>"
iso_application="xuan OS Live/Install ISO"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
buildmodes=("iso" "bootstrap")
architectures=("x86_64")
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=("-comp" "xz" "-Xbcj" "x86" "-Xdict-size" "1M" "-b" "1M")

bootmodes=("bios.syslinux.mbr" "bios.syslinux.eltorito" "uefi-ia32.grub.esp" "uefi-ia32.grub.eltorito" "uefi-x64.grub.esp" "uefi-x64.grub.eltorito")

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)
