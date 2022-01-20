#!/bin/bash
set -eu

# update if necessary and setup snapper for snapshot rollback
sudo pacman -Syyu --noconfirm
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo btrfs su de /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots

# enable timeline and cleanup (please edit snapper configs to your specific needs)
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
sudo systemctl enable --now snapper-boot.timer

# install desktop environment and some stuff
sudo pacman -S --noconfirm xorg-server xf86-video-intel xf86-input-synaptics plasma plasma-pa sddm konsole dolphin dolphin-plugins pipewire pipewire-pulse pipewire-alsa pipewire-jack kate chromium keepassxc packagekit-qt5 qbittorrent openssh micro xclip screen tree neofetch zsh zsh-syntax-highlighting zsh-autosuggestions

# enable display manager and ssh
sudo systemctl enable sddm
sudo systemctl enable sshd

neofetch