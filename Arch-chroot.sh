#!/bin/bash
set -eu

ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime
hwclock --systohc --utc
timedatectl set-ntp true
sed -i '160s/.//' /etc/locale.gen
locale-gen
sed -i '92s/.//' /etc/pacman.conf
sed -i '93s/.//' /etc/pacman.conf
reflector --country Hungary --protocol https --age 6 --sort rate --verbose --save /etc/pacman.d/mirrorlist
echo 'lenarch' >> /etc/hostname
echo '127.0.0.1	localhost' >> /etc/hosts
echo '::1		localhost' >> /etc/hosts
echo '127.0.1.1	lenarch.localdomain	lenarch' >> /etc/hosts
echo 'LANG=en_GB.UTF-8' >> /etc/locale.conf
echo 'KEYMAP=hu' >> /etc/vconsole.conf
echo 'permit persist razor as root' >> /etc/doas.conf
echo root:PASSWORD | chpasswd
useradd -m -g users -G wheel razor
echo razor:PASSWORD | chpasswd

pacman -Syyu --noconfirm
pacman -S --noconfirm grub efibootmgr os-prober btrfs-progs ntfs-3g dosfstools mtools linux-lts-headers base-devel doas xdg-user-dirs alsa-utils xdg-utils neofetch networkmanager network-manager-applet wpa_supplicant bluez bluez-utils tlp htop curl wget sh git acpi acpi_call-lts acpid nfs-utils rsync snapper dialog screen tree lvm2 micro xclip
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable acpid

sed -i '7s/.*/MODULES=(crc32c-intel btrfs)/' /etc/mkinitcpio.conf
sed -i '14s/.*/BINARIES=(dosfsck btrfsck)/' /etc/mkinitcpio.conf
sed -i '19s/.*/FILES=(\/root\/.keys\/espkey.bin \/root\/.keys\/rootkey.bin)/' /etc/mkinitcpio.conf
sed -i '52s/.*/HOOKS=(base udev autodetect keyboard keymap modconf block lvm2 encryptesp encrypt usr fsck resume shutdown)/' /etc/mkinitcpio.conf
sed -i '57s/.//' /etc/mkinitcpio.conf

echo 'zram' >> /etc/modules-load.d/zram.conf
echo 'options zram num_devices=4' >> /etc/modprobe.d/zram.conf
echo 'KERNEL=="zram0", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram0", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
echo 'KERNEL=="zram1", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram1", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
echo 'KERNEL=="zram2", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram2", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
echo 'KERNEL=="zram3", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram3", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules

cp /usr/lib/initcpio/install/encrypt /etc/initcpio/install/encryptesp
cp /usr/lib/initcpio/hooks/encrypt /etc/initcpio/hooks/encryptesp
sed -i 's/cryptdevice/cryptesp/' /etc/initcpio/hooks/encryptesp
sed -i 's/cryptkey/cryptespkey/' /etc/initcpio/hooks/encryptesp

mkdir /root/.keys
chmod 700 /root/.keys
head -c 64 /dev/urandom >> /root/.keys/espkey.bin
head -c 64 /dev/urandom >> /root/.keys/rootkey.bin
chmod 600 /root/.keys/espkey.bin
chmod 600 /root/.keys/rootkey.bin
echo "PASSWORD" | cryptsetup -v luksAddKey -i 1 /dev/sda1 /root/.keys/espkey.bin
echo "PASSWORD" | cryptsetup -v luksAddKey -i 1 /dev/mapper/vgroot-btrfs /root/.keys/rootkey.bin

ESP="$(blkid -s UUID -o value /dev/sda1)"
BTRFS="$(blkid -s UUID -o value /dev/mapper/vgroot-btrfs)"

sed -i '66,78 {s/^/#/}' /etc/grub.d/10_linux
sed -i '4s/5/3/' /etc/default/grub
sed -i '54s/.//' /etc/default/grub
sed -i '/above./a GRUB_DEFAULT=saved' /etc/default/grub
echo '$ESP','$BTRFS' | sed -i "6s/.*/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptesp=UUID=$ESP:esp cryptespkey=rootfs:\/root\/.keys\/espkey.bin cryptdevice=UUID=$BTRFS:root cryptkey=rootfs:\/root\/.keys\/rootkey.bin root=\/dev\/mapper\/root rw resume=\/dev\/mapper\/root resume_offset=\"/" /etc/default/grub
sed -i '13s/.//' /etc/default/grub
sed -i '/root ALL=(ALL) ALL/a razor ALL=(ALL) ALL' /etc/sudoers
sed -i '83s/# //' /etc/sudoers

sed -i 's/,subvolid=256,subvol=\/@//' /etc/fstab
echo '/dev/zram0		none		swap		defaults,pri=400	0 0' >> /etc/fstab
echo >> /etc/fstab
echo '/dev/zram1		none		swap		defaults,pri=400	0 0' >> /etc/fstab
echo >> /etc/fstab
echo '/dev/zram2		none		swap		defaults,pri=400	0 0' >> /etc/fstab
echo >> /etc/fstab
echo '/dev/zram3		none		swap		defaults,pri=400	0 0' >> /etc/fstab

btrfs su set-default 256 /
mkinitcpio -p linux-lts
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
grub-mkconfig -o /boot/grub/grub.cfg
neofetch