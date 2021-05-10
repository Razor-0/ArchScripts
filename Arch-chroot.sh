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

read -n 1 -s -r -p "Press any key to continue if everything installed correctly"

sed -i '7s/.*/MODULES=(crc32c-intel btrfs)/' /etc/mkinitcpio.conf
sed -i '14s/.*/BINARIES=(dosfsck btrfsck)/' /etc/mkinitcpio.conf
sed -i '19s/.*/FILES=(\/root\/.keys\/espkey.bin \/root\/.keys\/rootkey.bin)/' /etc/mkinitcpio.conf
sed -i '52s/.*/HOOKS=(base udev autodetect modconf block lvm2 encryptesp encrypt keyboard keymap usr fsck resume shutdown)' /etc/mkinitcpio.conf
sed -i '57s/.//' /etc/mkinitcpio.conf

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
cryptsetup -v luksAddKey -i 1 /dev/sda2 /root/.keys/espkey.bin
cryptsetup -v luksAddKey -i 1 /dev/vgroot/btrfs /root/.keys/rootkey.bin

mkinitcpio -p linux-lts

echo -e 'Edit grub.d, default grub and gen config then exit'