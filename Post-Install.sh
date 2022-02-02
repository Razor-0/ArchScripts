#!/bin/bash
set -eu

sudo pacman -Syyu --noconfirm
sudo pacman -S rsync snapper doas xorg-server xf86-video-intel xf86-input-synaptics plasma sddm konsole dolphin pipewire pipewire-pulse pipewire-alsa kate chromium openssh

sudo systemctl enable sddm
sudo systemctl enable sshd