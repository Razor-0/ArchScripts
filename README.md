# ArchScripts
 My stupidly extensive shell scripts to install Arch with LuKs and BTRFS Snapshots.
 This is mainly for me and my specific needs but feel free to use and edit as you need.
 It takes a OpenSUSE's subvolume layout to enable easily restored bootable snapshots on Arch.
 LuKs encryption is pretty self explanatory I do however also encrypt my boot part which most avoid.
 
 The scripts for my specific use case has been pretty much fully automatized, the user only needs to partition the disk, clone the repo and then run the scripts at their respective points (Partition and Arch-chroot). Keep in mind this is a pretty empty installation, it's far from complete or perfect and for most people this kind of partition layout will possibly be far more extensive than they'd ever want or need it to be.
 
 The installation has been heavily reworked, Post-Install was removed alongside a lot of pre-installed packages, root is also now mounted to the first snapshots location instead of the top layer while some things are configured differently and are more automated and reliable at setting the proper values.