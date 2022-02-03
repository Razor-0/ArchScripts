#!/bin/bash
set -eu

# syncing time and fixing time for dual boot
sudo timedatectl set-local-rtc 1 --adjust-system-clock
sudo timedatectl set-ntp true

# refreshing reflector and installing kde
sudo pacman -Syyu --noconfirm
sudo pacman -S snapper xorg-server xf86-video-intel xf86-input-synaptics plasma sddm konsole dolphin pipewire pipewire-pulse pipewire-alsa kate chromium micro xclip
sudo systemctl enable sddm

# creating snappers config
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo btrfs su de /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots

# enable 2GB zram pages per physical core on 4C/8T
sudo echo 'zram' >> /etc/modules-load.d/zram.conf
sudo echo 'options zram num_devices=4' >> /etc/modprobe.d/zram.conf
sudo echo 'KERNEL=="zram0", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram0", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
sudo echo 'KERNEL=="zram1", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram1", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
sudo echo 'KERNEL=="zram2", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram2", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
sudo echo 'KERNEL=="zram3", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram3", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules

# edit fstab for btrfs and add zram to automount
echo '/dev/zram0		none		swap		defaults,pri=4000	0 0' >> /etc/fstab
echo >> /etc/fstab
echo '/dev/zram1		none		swap		defaults,pri=8000	0 0' >> /etc/fstab
echo >> /etc/fstab
echo '/dev/zram2		none		swap		defaults,pri=16000	0 0' >> /etc/fstab
echo >> /etc/fstab
echo '/dev/zram3		none		swap		defaults,pri=32000	0 0' >> /etc/fstab