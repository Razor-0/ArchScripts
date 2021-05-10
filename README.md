# ArchScripts
 My stupidly extensive scripts to install Arch with LVM, LuKs and BTRFS Snapshots.
 This is mainly for me and my specific needs but feel free to use and edit as you need.
 It takes a twist on OpenSUSE's subvolume layout to enable proper bootable snapshots on Arch.
 LVM is setup for easier resizing and modifying of the root partititon as needed.
 LuKs encryption is pretty self explanatory I do however also encrypt my boot partititon which people commonly avoid.
 
 Keep in mind this isn't a complete script (yet!) and will need some manual changes in chroot in it's current form, I'm working on the remaining steps but I have no guarantees.