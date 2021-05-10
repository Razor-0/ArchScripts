ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime
hwclock --systohc --utc
timedatectl set-ntp true
sed -i '160s/.//' /etc/locale.gen
locale-gen
sed -i '92s/.//' /etc/pacman.conf
sed -i '93s/.//' /etc/pacman.conf
reflector --country Hungary --protocol https --age 6 --sort rate --verbose --save /etc/pacman.d/mirrorlist
echo "lenarch" >> /etc/hostname
echo "127.0.0.1	localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1	lenarch.localdomain	lenarch" >> /etc/hosts
echo "LANG=en_GB.UTF-8" >> /etc/locale.conf
echo "KEYMAP=hu" >> /etc/vconsole.conf
echo root:Hpp_73923 | chpasswd
useradd -m -g users -G wheel razor
echo razor:hpp73923 | chpasswd

pacman -Syyu
pacman -S grub efibootmgr os-prober btrfs-progs ntfs-3g dosfstools mtools linux-lts-headers base-devel doas xdg-user-dirs alsa-utils xdg-utils neofetch networkmanager network-manager-applet wpa_supplicant bluez bluez-utils tlp htop curl wget sh git acpi acpi_call-lts acpid nfs-utils openssh rsync snapper dialog screen tree
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable acpid

echo -e 'Edit grub.d, mkinitcpio, default grub and gen config then exit'