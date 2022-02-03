#!/bin/bash
set -eu

# syncing time and fixing time for dual boot
sudo timedatectl set-local-rtc 1 --adjust-system-clock
sudo timedatectl set-ntp true
timedatectl status

# refreshing reflector and installing kde
sudo pacman -Syyu --noconfirm
sudo pacman -S --noconfirm snapper xorg-server xf86-video-intel xf86-input-synaptics plasma sddm konsole dolphin pipewire pipewire-pulse pipewire-alsa kate chromium micro xclip
sudo systemctl enable sddm

# creating snappers config
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo btrfs su de /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots