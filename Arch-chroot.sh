ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime
hwclock --systohc --utc
timedatectl set-ntp true
sed -i '92s/.//' /etc/locale.gen