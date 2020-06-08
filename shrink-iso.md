# Shrink your ISO

## Shrink it

1.  Mount the image using another Linux (a Raspberry Pi works).
2.  Find the name of the device using *sudo fdisk -l* (in our case it's /dev/mmcblk0)
3.  Resize the filesystem
    * `sudo e2fsck -f /dev/mmcblk0p2`
    * `sudo resize2fs /dev/mmcblk0p2 7000M`
4.  Resize the partition (it must be larger than the file system):

    ```bash
    sudo parted /dev/mmcblk0 resizepart 2 7700M
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
sudo dd bs=1M count=7700 if=/dev/mmcblk0 of=$(date +%F)-poppy-ergo-jr.img status=progress
wget https://raw.githubusercontent.com/poppy-project/PiShrink/master/pishrink.sh
chmod +x pishrink.sh
sudo ./pishrink.sh $(date +%F)-poppy-ergo-jr.img $(date +%F)-poppy-ergo-jr.shrink.img
zip $(date +%F)-poppy-ergo-jr.img.zip $(date +%F)-poppy-ergo-jr.shrink.img
```
