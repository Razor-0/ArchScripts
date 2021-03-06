#!/bin/bash
set -eu

# refreshing reflector and installing kde
sudo pacman -Syyu --noconfirm
sudo pacman -S --noconfirm xorg-server xf86-input-synaptics plasma sddm konsole dolphin pipewire pipewire-pulse pipewire-alsa kate chromium git curl wget sh neofetch ttf-opensans micro xclip code zsh-autosuggestions zsh-syntax-highlighting

# creating snapper configs
sudo umount /.snapshots
sudo umount /home/.snapshots
sudo umount /storage/.snapshots
sudo rm -r /.snapshots
sudo rm -r /home/.snapshots
sudo rm -r /storage/.snapshots
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
sudo snapper -c storage create-config /storage
sudo btrfs su de /.snapshots
sudo btrfs su de /home/.snapshots
sudo btrfs su de /storage/.snapshots
sudo mkdir /.snapshots
sudo mkdir /home/.snapshots
sudo mkdir /storage/.snapshots
sudo mount -a
sudo chmod 750 /.snapshots
sudo chmod 750 /home/.snapshots
sudo chmod 750 /storage/.snapshots

# install paru pacman wrapper for AUR packages
git clone https://aur.archlinux.org/paru.git ~/Downloads/tmpParu
cd ~/Downloads/tmpParu
makepkg -sic PKGBUILD --noconfirm

mkdir ~/Downloads/Telegram
cd ~/Downloads/Telegram
wget https://github.com/telegramdesktop/tdesktop/releases/download/v3.5.2/tsetup.3.5.2.tar.xz
tar -xJvf tsetup.3.5.2.tar.xz
sudo mv Telegram /opt/telegram
sudo ln -sf /opt/telegram/Telegram /usr/bin/telegram