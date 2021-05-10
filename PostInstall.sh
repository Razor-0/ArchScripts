sudo umount /.snapshots
sudo umount /home/.snapshots
sudo rm -r /.snapshots
sudo rm -r /home/.snapshots
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
sudo btrfs su de /.snapshots
sudo btrfs su de /home/.snapshots
sudo mkdir /.snapshots
sudo mkdir /home/.snapshots
sudo mount -a
sudo chmod 750 /.snapshots
sudo chmod 750 /home/.snapshots

sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
sudo systemctl enable --now snapper-boot.timer

sudo pacman -Syyu --noconfirm
sudo pacman -S --noconfirm xorg xf86-video-intel xf86-input-synaptics nvidia nvidia-dkms plasma plasma-pa sddm pipewire pipewire-alsa pipewire-pulse pipewire-jack gst-plugin-pipewire pulseeffects pavucontrol konsole kate chromium dolphin dolphin-plugins packagekit-qt5 zsh zsh-autosuggestions zsh-syntax-highlighting openssh

sudo systemctl enable sddm
sudo systemctl enable sshd

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm PKGBUILD
cd

yay -S --answerclean all --noconfirm ttf-meslo-nerd-font-powerlevel10k snap-pac-grub