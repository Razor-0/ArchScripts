#!/bin/bash
set -eu

# basic configurations for the system (edit as needed for locale, hostname etc)
ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime
hwclock --systohc --utc # remove --utc if you're not dualbooting or you use the DE's time sync
timedatectl set-ntp true
sed -i '160s/.//' /etc/locale.gen # change the 160 to your locale's line number
locale-gen

sed -i '92s/.//' /etc/pacman.conf # comment this and the next command to not enable multilib
sed -i '93s/.//' /etc/pacman.conf

# edit this command to use the correct mirrorlist for your country
reflector --country Hungary --protocol https --age 6 --sort rate --verbose --save /etc/pacman.d/mirrorlist

echo 'lenarch' >> /etc/hostname # edit lenarch to whatever name you want for your PC
echo '127.0.0.1	localhost' >> /etc/hosts
echo '::1		localhost' >> /etc/hosts
echo '127.0.1.1	lenarch.localdomain	lenarch' >> /etc/hosts # change lenarch to the same name as your hostname
echo 'LANG=en_GB.UTF-8' >> /etc/locale.conf # edit en_GB with your locale from the locale.gen part
echo 'KEYMAP=hu' >> /etc/vconsole.conf # change hu to your keymap
echo 'permit persist razor as root' >> /etc/doas.conf # change razor to your user or uncomment this and remove doas from the pacman part if you don't need doas

echo root:PASSWORD | chpasswd # change PASSWORD with your root's password
useradd -m -g users -G wheel razor # change razor to your own username
echo razor:PASSWORD | chpasswd # same here for the user's PASSWORD

# edit as you see fit alongside the systemctl commands
pacman -Syyu --noconfirm
pacman -S --noconfirm grub efibootmgr os-prober btrfs-progs ntfs-3g dosfstools mtools linux-zen-headers base-devel doas xdg-user-dirs alsa-utils xdg-utils neofetch networkmanager network-manager-applet wpa_supplicant bluez bluez-utils tlp htop curl wget sh git acpi acpi_call-dkms acpid nfs-utils rsync snapper dialog screen tree lvm2 micro xclip linux-lts linux-lts-headers

# enable neccessities like Network, BT etc at boot
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable acpid

# modify initcpio modules, binaries, hooks etc
sed -i '7s/.*/MODULES=(crc32c-intel btrfs)/' /etc/mkinitcpio.conf
sed -i '14s/.*/BINARIES=(dosfsck btrfsck)/' /etc/mkinitcpio.conf
sed -i '19s/.*/FILES=(\/root\/.keys\/espkey.bin \/root\/.keys\/rootkey.bin)/' /etc/mkinitcpio.conf
sed -i '52s/.*/HOOKS=(base udev autodetect keyboard keymap modconf block lvm2 encryptesp encrypt usr fsck resume shutdown)/' /etc/mkinitcpio.conf
sed -i '57s/.//' /etc/mkinitcpio.conf

# enable 2GB zram pages per physical core on 4C/8T
echo 'zram' >> /etc/modules-load.d/zram.conf
echo 'options zram num_devices=4' >> /etc/modprobe.d/zram.conf
echo 'KERNEL=="zram0", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram0", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
echo 'KERNEL=="zram1", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram1", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
echo 'KERNEL=="zram2", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram2", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
echo 'KERNEL=="zram3", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram3", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules

# create hook to encrypt esp at boot
cp /usr/lib/initcpio/install/encrypt /etc/initcpio/install/encryptesp
cp /usr/lib/initcpio/hooks/encrypt /etc/initcpio/hooks/encryptesp
sed -i 's/cryptdevice/cryptesp/' /etc/initcpio/hooks/encryptesp
sed -i 's/cryptkey/cryptespkey/' /etc/initcpio/hooks/encryptesp

# create keys to unlock esp and root at boot
mkdir /root/.keys
chmod 700 /root/.keys
head -c 64 /dev/urandom >> /root/.keys/espkey.bin
head -c 64 /dev/urandom >> /root/.keys/rootkey.bin
chmod 600 /root/.keys/espkey.bin
chmod 600 /root/.keys/rootkey.bin
echo "PASSWORD" | cryptsetup -v luksAddKey -i 1 /dev/sda1 /root/.keys/espkey.bin # edit PASSWORD
echo "PASSWORD" | cryptsetup -v luksAddKey -i 1 /dev/mapper/vgroot-btrfs /root/.keys/rootkey.bin # same here

# set temp environment value to include in grub config
ESP="$(blkid -s UUID -o value /dev/sda1)"
BTRFS="$(blkid -s UUID -o value /dev/mapper/vgroot-btrfs)"

# edit grub config and grubd to make btrfs decide the default subvolume
sed -i '66,78 {s/^/#/}' /etc/grub.d/10_linux
sed -i '4s/5/3/' /etc/default/grub
sed -i '54s/.//' /etc/default/grub
sed -i '/above./a GRUB_DEFAULT=saved' /etc/default/grub
echo '$ESP','$BTRFS' | sed -i "6s/.*/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptesp=UUID=$ESP:esp cryptespkey=rootfs:\/root\/.keys\/espkey.bin cryptdevice=UUID=$BTRFS:root cryptkey=rootfs:\/root\/.keys\/rootkey.bin root=\/dev\/mapper\/root rw resume=\/dev\/mapper\/root resume_offset=16400\"/" /etc/default/grub
sed -i '13s/.//' /etc/default/grub
sed -i '/root ALL=(ALL) ALL/a razor ALL=(ALL) ALL' /etc/sudoers # change razor with your username or comment out to use the wheel group only
sed -i '83s/# //' /etc/sudoers

# edit fstab for btrfs and add zram to automount
sed -i 's/,subvolid=256,subvol=\/@//' /etc/fstab
echo '/dev/zram0		none		swap		defaults,pri=400	0 0' >> /etc/fstab
echo >> /etc/fstab
echo '/dev/zram1		none		swap		defaults,pri=400	0 0' >> /etc/fstab
echo >> /etc/fstab
echo '/dev/zram2		none		swap		defaults,pri=400	0 0' >> /etc/fstab
echo >> /etc/fstab
echo '/dev/zram3		none		swap		defaults,pri=400	0 0' >> /etc/fstab

# set default btrfs subvolume for snapper and install grub, gen init and grub config
btrfs su set-default 256 /
mkinitcpio -p linux-zen
mkinitcpio -p linux-lts
grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable
grub-mkconfig -o /boot/grub/grub.cfg
neofetch