# Shrink your ISO

## Make an image file

1.  Mount the image using another Linux (a Raspberry Pi works).
2.  Find the name of the device using *sudo fdisk -l* (in our case it's /dev/mmcblk0)
3.  Use dd to make a copy\
```bash
sudo dd if=/dev/mmcblk0 of=$(date +%F)-poppy-ergo-jr.img status=progress
```

## Shrink and compress it

Shrink and zip the image using pishrink:

```bash
wget https://raw.githubusercontent.com/poppy-project/PiShrink/master/pishrink.sh
chmod +x pishrink.sh
sudo ./pishrink.sh -z $(date +%F)-poppy-ergo-jr.img $(date +%F)-poppy-ergo-jr.shrink.img.gz
```
