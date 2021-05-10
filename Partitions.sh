echo 'Just a moment, we are creating partitions...'
# cryptsetup open --type plain -d /dev/urandom /dev/sda3 tbw
# dd if=/dev/zero of=/dev/mapper/tbw bs=1M status=progress
# dd if=/dev/mapper/tbw bs=1M status=progress | od | head
# cryptsetup close tbw

pvcreate /dev/sda3
vgcreate vgroot /dev/sda3
lvcreate -l 100%FREE -n btrfs vgroot
cryptsetup luksFormat --type luks1 --use-urandom -h sha1 -i 1000 /dev/sda2
cryptsetup open /dev/sda2 esp
cryptsetup luksFormat --type luks2 --use-urandom -h sha512 -i 1000 /dev/vgroot/btrfs
cryptsetup open /dev/vgroot/btrfs root
mkfs.vfat -F12 /dev/sda1
mkfs.vfat -F32 /dev/mapper/esp
mkfs.btrfs -L 'Crypt Btrfs' /dev/mapper/root

mount /dev/mapper/root /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@/home
btrfs su cr /mnt/@/root
btrfs su cr /mnt/@/opt
btrfs su cr /mnt/@/srv
btrfs su cr /mnt/@/swap
btrfs su cr /mnt/@/tmp
btrfs su cr /mnt/@/snapshots
btrfs su cr /mnt/@/snapshots/home
btrfs su cr /mnt/@/snapshots/root
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

mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@ /dev/mapper/root /mnt
mkdir -p /mnt/{boot,.snapshots,.win}
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/home /dev/mapper/root /mnt/home
mkdir /mnt/home/.snapshots
mkdir -p /mnt/.win/{ssd,hdd,ehdd,usb,iso}
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/root /dev/mapper/root /mnt/root
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/opt /dev/mapper/root /mnt/opt
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/srv /dev/mapper/root /mnt/srv
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,swap,subvol=@/swap /dev/mapper/root /mnt/swap
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/tmp /dev/mapper/root /mnt/tmp
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/cache /dev/mapper/root /mnt/var/cache
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/crash /dev/mapper/root /mnt/var/crash
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/log /dev/mapper/root /mnt/var/log
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/opt /dev/mapper/root /mnt/var/opt
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/spool /dev/mapper/root /mnt/var/spool
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/tmp /dev/mapper/root /mnt/var/tmp
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/lib/libvirt/images /dev/mapper/root /mnt/var/lib/libvirt/images
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/lib/machines /dev/mapper/root /mnt/var/lib/machines
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/lib/portables /dev/mapper/root /mnt/var/lib/portables
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/lib/mailman /dev/mapper/root /mnt/var/lib/mailman
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/lib/named /dev/mapper/root /mnt/var/lib/named
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/lib/mariadb /dev/mapper/root /mnt/var/lib/mariadb
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/lib/mysql /dev/mapper/root /mnt/var/lib/mysql
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/var/lib/pgqsl /dev/mapper/root /mnt/var/lib/pgqsl
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/usr/local /dev/mapper/root /mnt/usr/local
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/snapshots/home /dev/mapper/root /mnt/home/.snapshots
mount -o defaults,discard,noatime,compress=zstd:3,space_cache=v2,subvol=@/snapshots/root /dev/mapper/root /mnt/.snapshots
mount /dev/mapper/esp /mnt/boot
mkdir /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

echo -e 'Nd we are done! \nPlease make sure everything has been created properly!'
lsblk