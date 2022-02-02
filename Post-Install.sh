#!/bin/bash
set -eu

# refreshing reflector and installing kde
sudo reflector --country Netherlands --latest 4 --protocol https --sort rate --verbose --save /etc/pacman.d/mirrorlist
sudo pacman -Syyu --noconfirm
sudo pacman -S rsync snapper doas xorg-server xf86-video-intel xf86-input-synaptics plasma sddm konsole dolphin pipewire pipewire-pulse pipewire-alsa kate chromium openssh

# enabling some required stuff
sudo systemctl enable sddm
sudo systemctl enable sshd
sudo systemctl enable reflector.timer
sudo systemctl enable tlp
sudo systemctl enable acpid

# creating snappers config
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo btrfs su de /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots