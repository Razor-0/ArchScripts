#!/bin/bash
set -eu

sudo pacman -Syyu --noconfirm
sudo pacman -S rsync snapper doas xorg-server xf86-video-intel xf86-input-synaptics plasma sddm konsole dolphin pipewire pipewire-pulse pipewire-alsa kate chromium openssh reflector

sudo systemctl enable sddm
sudo systemctl enable sshd
sudo systemctl enable reflector.timer

sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo btrfs su de /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots