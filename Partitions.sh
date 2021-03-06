#!/bin/bash
set -eu

# change the PASSWORD in all 4 of these lines (first to create then to open said LuKs part)
echo "PASSWORD" | cryptsetup -q luksFormat --type luks1 --use-urandom -h sha256 -i 1000 /dev/sda2
echo "PASSWORD" | cryptsetup luksOpen /dev/sda2 boot
echo "PASSWORD" | cryptsetup -q luksFormat --type luks2 --use-urandom -h sha512 -i 1000 /dev/sda3
echo "PASSWORD" | cryptsetup luksOpen /dev/sda3 root
echo "PASSWORD" | cryptsetup -q luksFormat --type luks2 --use-urandom -h sha512 -i 1000 /dev/sdb1
echo "PASSWORD" | cryptsetup luksOpen /dev/sdb1 storage

# formatting partitions with the following filesystems
mkfs.vfat -F32 /dev/sda1
fatlabel /dev/sda1 Bootloader
echo 'y' | mkfs.reiserfs -l Kernels /dev/mapper/boot
mkfs.btrfs -L 'Btrfs Root' -R free-space-tree,quota /dev/mapper/root
mkfs.btrfs -L 'Btrfs Storage' -R free-space-tree,quota /dev/mapper/storage

# creating btrfs subvols for snapshots
mount /dev/mapper/root /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@/.snapshots
mkdir /mnt/@/.snapshots/1
mkdir /mnt/@/home
btrfs su cr /mnt/@/home/.snapshots
mkdir /mnt/@/home/.snapshots/1
btrfs su cr /mnt/@/root
btrfs su cr /mnt/@/opt
btrfs su cr /mnt/@/srv
btrfs su cr /mnt/@/.swap
mkdir -p /mnt/@/var/lib/libvirt
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
btrfs su cr /mnt/@/var/lib/docker
mkdir /mnt/@/usr
btrfs su cr /mnt/@/usr/local
btrfs su cr /mnt/@/home/.snapshots/1/snapshot
btrfs su cr /mnt/@/.snapshots/1/snapshot

# create origin snapshot of system
echo '<?xml version="1.0"?>' >> /mnt/@/.snapshots/1/info.xml
echo '<snapshot>' >> /mnt/@/.snapshots/1/info.xml
echo '	<type>single</type>' >> /mnt/@/.snapshots/1/info.xml
echo -e '	<num>1</num> \n' >> /mnt/@/.snapshots/1/info.xml
DATE="$(date +"%Y-%m-%d %H:%M:%S")"
echo '$DATE' | sed -i "5s/.*/	<date>$DATE<\/date>/" /mnt/@/.snapshots/1/info.xml
echo '	<description>Original Root Filesystem</description>' >> /mnt/@/.snapshots/1/info.xml
echo '</snapshot>' >> /mnt/@/.snapshots/1/info.xml
btrfs su set-default $(btrfs su li /mnt | grep "@/.snapshots/1/snapshot" | grep -oP '(?<=ID )[0-9]+') /mnt

echo '<?xml version="1.0"?>' >> /mnt/@/home/.snapshots/1/info.xml
echo '<snapshot>' >> /mnt/@/home/.snapshots/1/info.xml
echo '	<type>single</type>' >> /mnt/@/home/.snapshots/1/info.xml
echo -e '	<num>1</num> \n' >> /mnt/@/home/.snapshots/1/info.xml
DATE2="$(date +"%Y-%m-%d %H:%M:%S")"
echo '$DATE2' | sed -i "5s/.*/	<date>$DATE2<\/date>/" /mnt/@/home/.snapshots/1/info.xml
echo '	<description>Original Home Filesystem</description>' >> /mnt/@/home/.snapshots/1/info.xml
echo '</snapshot>' >> /mnt/@/home/.snapshots/1/info.xml
umount /mnt

# mounting the subvolumes and partititons
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/.snapshots/1/snapshot /dev/mapper/root /mnt
mkdir -p /mnt/var/{cache,crash,log,opt,spool,tmp,lib}
mkdir -p /mnt/var/lib/{libvirt/images,machines,portables,mailman,named,mariadb,mysql,pgqsl,docker}
mkdir -p /mnt/{boot,.grub/EFI,.drives,.snapshots,home,srv,opt,.swap,root,storage,.windows,usr/local}
mkdir -p /mnt/.windows/{System,Storage}
mount -o defaults /dev/mapper/boot /mnt/boot
mount -o defaults /dev/sda1 /mnt/.grub/EFI
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/home/.snapshots/1/snapshot /dev/mapper/root /mnt/home
mkdir /mnt/home/.snapshots
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/home/.snapshots /dev/mapper/root /mnt/home/.snapshots
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/docker /dev/mapper/root /mnt/var/lib/docker
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/root /dev/mapper/root /mnt/root
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/opt /dev/mapper/root /mnt/opt
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/srv /dev/mapper/root /mnt/srv
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,swap,subvol=@/.swap /dev/mapper/root /mnt/.swap
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/cache /dev/mapper/root /mnt/var/cache
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/crash /dev/mapper/root /mnt/var/crash
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/log /dev/mapper/root /mnt/var/log
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/opt /dev/mapper/root /mnt/var/opt
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/spool /dev/mapper/root /mnt/var/spool
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/tmp /dev/mapper/root /mnt/var/tmp
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/libvirt/images /dev/mapper/root /mnt/var/lib/libvirt/images
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/machines /dev/mapper/root /mnt/var/lib/machines
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/portables /dev/mapper/root /mnt/var/lib/portables
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/mailman /dev/mapper/root /mnt/var/lib/mailman
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/named /dev/mapper/root /mnt/var/lib/named
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/mariadb /dev/mapper/root /mnt/var/lib/mariadb
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/mysql /dev/mapper/root /mnt/var/lib/mysql
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/var/lib/pgqsl /dev/mapper/root /mnt/var/lib/pgqsl
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/usr/local /dev/mapper/root /mnt/usr/local
mount -o defaults,commit=240,flushoncommit,autodefrag,ssd_spread,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/.snapshots /dev/mapper/root /mnt/.snapshots
mount /dev/mapper/storage /mnt/storage
btrfs su cr /mnt/storage/@
btrfs su cr /mnt/storage/@/.snapshots
mkdir /mnt/storage/@/.snapshots/1
btrfs su cr /mnt/storage/@/.snapshots/1/snapshot
echo '<?xml version="1.0"?>' >> /mnt/storage/@/.snapshots/1/info.xml
echo '<snapshot>' >> /mnt/storage/@/.snapshots/1/info.xml
echo '	<type>single</type>' >> /mnt/storage/@/.snapshots/1/info.xml
echo -e '	<num>1</num> \n' >> /mnt/storage/@/.snapshots/1/info.xml
DATE3="$(date +"%Y-%m-%d %H:%M:%S")"
echo '$DATE3' | sed -i "5s/.*/	<date>$DATE3<\/date>/" /mnt/storage/@/.snapshots/1/info.xml
echo '	<description>Original Storage Filesystem</description>' >> /mnt/storage/@/.snapshots/1/info.xml
echo '</snapshot>' >> /mnt/storage/@/.snapshots/1/info.xml
umount /mnt/storage
mount -o defaults,commit=240,flushoncommit,autodefrag,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/.snapshots/1/snapshot /dev/mapper/storage /mnt/storage
mkdir /mnt/storage/.snapshots
mount -o defaults,commit=240,flushoncommit,autodefrag,discard=async,relatime,compress=zstd:5,space_cache=v2,subvol=@/.snapshots /dev/mapper/storage /mnt/storage/.snapshots
mount -o defaults /dev/sda6 /mnt/.windows/System
mount -o defaults /dev/sdb2 /mnt/.windows/Storage
chmod 750 /mnt/root
chmod 1777 /mnt/var/tmp

# disabling copy-on-write for performance
chattr +C /mnt/var/lib/mariadb
chattr +C /mnt/var/lib/mysql
chattr +C /mnt/var/lib/pgqsl
chattr +C /mnt/var/lib/libvirt/images
chattr +C /mnt/var/cache
chattr +C /mnt/var/log
chattr +C /mnt/var/spool
chattr +C /mnt/var/tmp
chattr +C /mnt/var/lib/docker

# creating and disabling cow on the swapfile
truncate -s 0 /mnt/.swap/swapfile
chattr +C /mnt/.swap/swapfile
dd if=/dev/zero of=/mnt/.swap/swapfile bs=1M count=24576 status=progress
chmod 600 /mnt/.swap/swapfile
mkswap /mnt/.swap/swapfile
swapon -p 0 /mnt/.swap/swapfile

# installing base system and some neccessities
pacstrap /mnt base linux-zen linux-firmware intel-ucode nano
genfstab -U /mnt >> /mnt/etc/fstab
sed -i 's/,subvolid=280,subvol=\/@\/.snapshots\/1\/snapshot//' /mnt/etc/fstab
lsblk -f