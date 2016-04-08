# Shrink your ISO

## Shrink it
* Mount the image using another Linux (a Raspberry-Pi works).
* Find the name of the device using *fdisk -l* (in our case it's /dev/sda)
* Resize the filesystem
    * *sudo e2fsck -f /dev/sda2*
    * *sudo resize2fs /dev/sda2 3000M* (3G is enough for us)
* Resize the partition
    * *sudo parted /dev/sda resizepart 2 3500M*

##  Expand it on first boot
* Boot on the card freshly shrinked
* Run raspi-config to expand the partition
    * *sudo raspi-config --expand-rootfs*
* Halt the system

## Make an image file
 * copy the image using dd and count
    * *sudo dd bs=1m count=4000 if=/dev/rdisk2 of=poppy-ergo-jr.iso*
