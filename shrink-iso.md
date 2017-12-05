# Shrink your ISO

## Shrink it

1.  Mount the image using another Linux (a Raspberry Pi works).
2.  Find the name of the device using *sudo fdisk -l* (in our case it's /dev/sda)
3.  Resize the filesystem
    * `sudo e2fsck -f /dev/sda2`
    * `sudo resize2fs /dev/sda2 3400M`
4.  Resize the partition (it must be larger than the file system):

    ```bash
    sudo parted /dev/sda resizepart 2 3450M
    ```

##  Expand it on first boot

1.  Boot on the card freshly shrinked.
2.  Run raspi-config to expand the partition:

    ```bash
    sudo raspi-config --expand-rootfs
    ```
3. Halt the system

## Make an image file

Copy the image using dd and count:

```bash
sudo dd bs=1m count=3500 if=/dev/rdisk2 of=$(date +%F)-poppy-ergo-jr.img
```
