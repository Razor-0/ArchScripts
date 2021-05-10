ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime
hwclock --systohc --utc
timedatectl set-ntp true
sed -i '160s/.//' /etc/locale.gen
locale-gen
sed -i '92s/.//' /etc/pacman.conf
sed -i '93s/.//' /etc/pacman.conf
reflector --country Hungary --protocol https --age 6 --sort rate --verbose --save /etc/pacman.d/mirrorlist
printf 'lenarch' >> /etc/hostname
printf '127.0.0.1	localhost' >> /etc/hosts
printf '::1		localhost' >> /etc/hosts
printf '127.0.1.1	lenarch.localdomain	lenarch' >> /etc/hosts
printf 'LANG=en_GB.UTF-8' >> /etc/locale.conf
printf 'KEYMAP=hu' >> /etc/vconsole.conf
printf 'permit persist razor as root' >> /etc/doas.conf
printf root:PASSWORD | chpasswd
useradd -m -g users -G wheel razor
printf razor:PASSWORD | chpasswd

pacman -Syyu --noconfirm
pacman -S --noconfirm grub efibootmgr os-prober btrfs-progs ntfs-3g dosfstools mtools linux-lts-headers base-devel doas xdg-user-dirs alsa-utils xdg-utils neofetch networkmanager network-manager-applet wpa_supplicant bluez bluez-utils tlp htop curl wget sh git acpi acpi_call-lts acpid nfs-utils openssh rsync snapper dialog screen tree lvm2
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

printf 'zram' >> /etc/modules-load.d/zram.conf
printf 'options zram num_devices=4' >> /etc/modprobe.d/zram.conf
printf 'KERNEL=="zram0", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram0", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
printf 'KERNEL=="zram1", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram1", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
printf 'KERNEL=="zram2", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram2", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules
printf 'KERNEL=="zram3", ATTR{disksize}="2048M" RUN="/usr/bin/mkswap /dev/zram3", TAG+="systemd"' >> /etc/udev/rules.d/99-zram.rules

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
printf "PASSWORD" | cryptsetup -v luksAddKey -i 1 /dev/sda2 /root/.keys/espkey.bin
printf "PASSWORD" | cryptsetup -v luksAddKey -i 1 /dev/vgroot/btrfs /root/.keys/rootkey.bin

ESP="$(blkid -s UUID -o value /dev/mapper/esp)"
BTRFS="$(blkid -s UUID -o value /dev/mapper/vgroot-btrfs)"

sed -i '66,78 {s/^/#/}' /etc/grub.d/10_linux
sed -i '4s/5/3/' /etc/default/grub
sed -i '54s/.//' /etc/default/grub
sed -i '/above./a GRUB_DEFAULT=saved' /etc/default/grub
printf '$ESP','$BTRFS' | sed -i "6s/.*/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptesp=UUID=$ESP cryptespkey=rootfs:\/root\/.keys\/espkey.bin cryptdevice=UUID=$BTRFS cryptkey=rootfs:\/root\/.keys\/rootkey.bin root=\/dev\/mapper\/root rw resume=\/dev\/mapper\/root resume_offset=\"/' /etc/default/grub
sed -i '13s/.//" /etc/default/grub
btrfs su set-default 256 /
mkinitcpio -p linux-lts
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

printf 'Edit grub-config and generate it, edit fstab and visduo then exit'