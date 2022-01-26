#!/bin/bash
set -eu

# create LuKs boot and LuKs root
# change the PASSWORD in all 4 of these lines (first to create then to open said LuKs part)
echo "PASSWORD" | cryptsetup -q luksFormat --type luks2 --use-urandom -h sha2 -i 1000 /dev/sda2
echo "PASSWORD" | cryptsetup luksOpen /dev/sda2 boot

echo "PASSWORD" | cryptsetup -q luksFormat --type luks2 --use-urandom -h sha512 -i 1000 /dev/sda3
echo "PASSWORD" | cryptsetup luksOpen /dev/sda3 root

# formatting partitions with the following filesystems
mkfs.vfat -F32 /dev/sda1
fatlabel /dev/sda1 Bootloaders
mkfs.reiserfs -l Kernels /dev/mapper/boot
mkfs.btrfs -L 'Btrfs Root' /dev/mapper/root

# creating btrfs subvols for snapshots
mount /dev/mapper/root /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@/home
btrfs su cr /mnt/@/root
btrfs su cr /mnt/@/opt
btrfs su cr /mnt/@/srv
btrfs su cr /mnt/@/.swap
btrfs su cr /mnt/@/snapshots
btrfs su cr /mnt/@/snapshots/root
btrfs su cr /mnt/@/snapshots/home
mkdir -p /mnt/@/var/lib/libvirt
mkdir /mnt/@/usr
btrfs su cr /mnt/@/var/cache
btrfs su cr /mnt/@/var/crash
btrfs su cr /mnt/@/var/log
btrfs su cr /mnt/@/var/opt
btrfs su cr /mnt/@/var/spool
btrfs su cr /mnt/@/var/tmp
btrfs su cr /mnt/@/var/lib/libvirt/images
btrfs su cr /mnt/@/var/lib/machines
btrfs su cr /mnt/@/var/lib/portables
btrfs su cr /mnt/@/var/lib/mailman
btrfs su cr /mnt/@/var/lib/named
btrfs su cr /mnt/@/var/lib/mariadb
btrfs su cr /mnt/@/var/lib/mysql
btrfs su cr /mnt/@/var/lib/pgqsl
btrfs su cr /mnt/@/usr/local
umount /mnt

# mounting the subvolumes and partititons
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@ /dev/mapper/root /mnt
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/home /dev/mapper/root /mnt/home
mkdir /mnt/home/.snapshots
mkdir -p /mnt/{boot,.win,.snapshots}
mkdir -p /mnt/.win/{ssd,hdd,ehdd,usb,iso}
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/root /dev/mapper/root /mnt/root
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/opt /dev/mapper/root /mnt/opt
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/srv /dev/mapper/root /mnt/srv
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,swap,subvol=@/.swap /dev/mapper/root /mnt/.swap
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/cache /dev/mapper/root /mnt/var/cache
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/crash /dev/mapper/root /mnt/var/crash
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/log /dev/mapper/root /mnt/var/log
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/opt /dev/mapper/root /mnt/var/opt
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/spool /dev/mapper/root /mnt/var/spool
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/tmp /dev/mapper/root /mnt/var/tmp
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/libvirt/images /dev/mapper/root /mnt/var/lib/libvirt/images
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/machines /dev/mapper/root /mnt/var/lib/machines
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/portables /dev/mapper/root /mnt/var/lib/portables
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/mailman /dev/mapper/root /mnt/var/lib/mailman
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/named /dev/mapper/root /mnt/var/lib/named
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/mariadb /dev/mapper/root /mnt/var/lib/mariadb
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/mysql /dev/mapper/root /mnt/var/lib/mysql
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/pgqsl /dev/mapper/root /mnt/var/lib/pgqsl
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/usr/local /dev/mapper/root /mnt/usr/local
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/snapshots/root /dev/mapper/root /mnt/.snapshots
mount -o defaults,autodefrag,discard,noatime,compress=zstd:5,space_cache=v2,subvol=@/snapshots/home /dev/mapper/root /mnt/home/.snapshots
mount /dev/mapper/boot /mnt/boot
mkdir /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
mount -o defaults /dev/sda6 /mnt/.win/ssd
mount -o defaults /dev/sdb2 /mnt/.win/hdd
chmod 750 /mnt/root
chmod 1777 /mnt/var/tmp

# disabling cow for some folders for performance
chattr +C /mnt/var/lib/libvirt/images
chattr +C /mnt/var/lib/mariadb
chattr +C /mnt/var/lib/mysql
chattr +C /mnt/var/lib/pgqsl

# creating and disabling cow on the swapfile
truncate -s 0 /mnt/.swap/swapfile
chattr +C /mnt/.swap/swapfile
dd if=/dev/zero of=/mnt/.swap/swapfile bs=1M count=24576 status=progress # edit count value to change swap's size
chmod 600 /mnt/.swap/swapfile
mkswap /mnt/.swap/swapfile
swapon -p 0 /mnt/.swap/swapfile # edit -p value to set different priority per requirements

# installing base system and some neccessities
pacstrap /mnt base linux-zen linux-firmware nano intel-ucode reflector
genfstab -U /mnt >> /mnt/etc/fstab
lsblk -f