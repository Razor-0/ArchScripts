# ArchScripts
 My stupidly extensive shell scripts to install Arch with LVM, LuKs and BTRFS Snapshots.
 This is mainly for me and my specific needs but feel free to use and edit as you need.
 It takes a twist on OpenSUSE's subvolume layout to enable easy to restore bootable snapshots on Arch.
 LVM is setup for easier resizing and modifying of the root partititon as needed.
 LuKs encryption is pretty self explanatory I do however also encrypt my boot part which most avoid.
 
 The Script for my specific use case has been 95% automatized, the user only needs to partition the disk, clone the repo and then run the scripts at their respective points (Partition - ArchISO, Arch-chroot - self-explanatory and lastly Postinstall - in the os itself, other than these you only need to use the shutdown -r now (and exit for chroot) respectively to move on to the next part.
 
 The scripts setup a pretty empty installation it's by far from complete or perfect and for most people will possibly be far more extensive than they'd ever want or need it to be.