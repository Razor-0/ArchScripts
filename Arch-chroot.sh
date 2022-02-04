#!/bin/bash
set -eu

# basic configurations for the system (edit as needed for locale, hostname etc)
ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime
hwclock --systohc
sed -i '160s/#//' /etc/locale.gen
locale-gen
sed -i '93s/#//' /etc/pacman.conf
sed -i '94s/#//' /etc/pacman.conf

# host file and keyboard configuration
echo 'lenarch' >> /etc/hostname
echo '127.0.0.1	localhost' >> /etc/hosts
echo '::1		localhost' >> /etc/hosts
echo '127.0.1.1	lenarch.localdomain lenarch' >> /etc/hosts
echo 'LANG=en_GB.UTF-8' >> /etc/locale.conf
echo 'KEYMAP=hu' >> /etc/vconsole.conf

# change password and username as needed
echo root:PASSWORD | chpasswd
useradd -m -G wheel -c "Kosa Mark" razor
echo razor:PASSWORD | chpasswd

# edit as you see fit alongside the systemctl commands
pacman -Syyu --noconfirm
pacman -S --noconfirm grub efibootmgr os-prober btrfs-progs ntfs-3g linux-zen-headers base-devel networkmanager bluez bluez-utils

# enable neccessities like Network, BT etc at boot
systemctl enable NetworkManager
systemctl enable bluetooth

# modify initcpio modules, binaries, hooks etc
sed -i '7s/.*/MODULES=(crc32c-intel btrfs)/' /etc/mkinitcpio.conf
sed -i '14s/.*/BINARIES=(dosfsck btrfsck)/' /etc/mkinitcpio.conf
sed -i '19s/.*/FILES=(\/root\/.keys\/bootkey.bin \/root\/.keys\/rootkey.bin)/' /etc/mkinitcpio.conf
sed -i '52s/.*/HOOKS=(base udev autodetect keyboard keymap modconf block encryptboot encrypt resume usr fsck shutdown)/' /etc/mkinitcpio.conf
sed -i '57s/#//' /etc/mkinitcpio.conf

# create hook to decrypt boot
cp /usr/lib/initcpio/install/encrypt /etc/initcpio/install/encryptboot
cp /usr/lib/initcpio/hooks/encrypt /etc/initcpio/hooks/encryptboot
sed -i 's/cryptdevice/cryptboot/' /etc/initcpio/hooks/encryptboot
sed -i 's/cryptkey/cryptbootkey/' /etc/initcpio/hooks/encryptboot

# create keys to unlock boot and root
mkdir /root/.keys
chmod 700 /root/.keys
head -c 64 /dev/urandom >> /root/.keys/bootkey.bin
head -c 64 /dev/urandom >> /root/.keys/rootkey.bin
chmod 600 /root/.keys/bootkey.bin
chmod 600 /root/.keys/rootkey.bin
echo "PASSWORD" | cryptsetup -v luksAddKey -i 1 /dev/sda2 /root/.keys/bootkey.bin
echo "PASSWORD" | cryptsetup -v luksAddKey -i 1 /dev/sda3 /root/.keys/rootkey.bin

# set temp environment value to include in grub config
BOOT="$(blkid -s UUID -o value /dev/sda2)"
ROOT="$(blkid -s UUID -o value /dev/sda3)"

# edit grub config and grubd to make btrfs decide the default subvolume
sed -i '66,78 {s/^/#/}' /etc/grub.d/10_linux
sed -i '74,86 {s/^/#/}' /etc/grub.d/20_linux_xen
sed -i '4s/5/8/' /etc/default/grub
sed -i '13s/#//' /etc/default/grub
sed -i '54s/#//' /etc/default/grub
sed -i '/above./a GRUB_DEFAULT=saved' /etc/default/grub
echo '$BOOT','$ROOT' | sed -i "6s/.*/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptboot=UUID=$BOOT:boot cryptbootkey=rootfs:\/root\/.keys\/bootkey.bin cryptdevice=UUID=$ROOT:root cryptkey=rootfs:\/root\/.keys\/rootkey.bin root=\/dev\/mapper\/root rw resume=\/dev\/mapper\/root resume_offset=16400\"/" /etc/default/grub

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

# add sudo privileges to the user
echo 'razor ALL=(ALL) ALL' | EDITOR=tee visudo /etc/sudoers.d/rootusers
visudo -c /etc/sudoers.d/rootusers

# set default btrfs subvolume for snapper and install grub, gen init and grub config
mkinitcpio -p linux-zen
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Arch Linux x64"
grub-mkconfig -o /boot/grub/grub.cfg