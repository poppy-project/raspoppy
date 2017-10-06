
# Raspoppy: Utility tools to setup a Raspberry Pi for Poppy robots

This repository regroups the set of tools we use to setup a Raspberry Pi board for a Poppy robot.

While we try to keep this procedure as simple as possible, it still requires a good knowledge of Linux OS and of Python. For those who are not interested in digging into those details, we provide ready-to-use SD-card images which can be directly downloaded and copy into your Raspberry.

*This procedure is mainly designed for the Raspberry Pi 2 and 3. However, some parts (especially all conda recipes) should also work for the odroid XU4 as both boards used an armv7 CPU. It is also important to note that this procedure is only given as an example: i.e. this is how we build the SD-card images we provide. Yet, you can freely adapt to better match your needs.*

## Current SD card ISO version: 2.0.0

* [x] Default user: `poppy` password: `poppy`
* [x] Default hostname: poppy
* [x] Python 2.7.10 [miniconda latest - 3.18.3](http://repo.continuum.io/miniconda/Miniconda3-3.18.3-Linux-armv7l.sh) distribution for linux-armv7
* [x] Conda recipes for linux-armv7 (on the [poppy-project](https://anaconda.org/poppy-project/) channel):
    * [x] explauto 1.2.0
    * [x] Flask 0.10.1
    * [x] hampy 1.4.1
    * [x] ikpy 2.2.1
    * [x] jupyter 4.0.6
    * [x] matplotlib 1.5.0
    * [x] nbextensions alpha
    * [x] numpy 1.9.2
    * [x] opencv 3.1.0
    * [x] poppy-creatures 2.0.0
    * [x] poppy-ergo-jr 2.0.0
    * [x] pypot 3.0.1
    * [x] scipy 0.16.0 (need libgfortran3)
* [x] auto start jupyter at boot
* [x] auto start web interface at boot
* [x] Snap!
* [x] enable RPI-camera (v4l2 driver)
* [x] setup serial communication

## Update

## Manual install

### Install Raspbian

Just follow standard [instructions](https://www.raspberrypi.org/downloads/raspbian/) from raspberry.org. We use [Raspbian Stretch Lite *2017-09-07* image](https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2017-09-08/2017-09-07-raspbian-stretch-lite.zip).

You will need to make sure that you have enough free space in your raspberry. The easiest way is to use the `raspi-config` script to expand your partition to the full SD-card. Just log into your Raspberry Pi and run:

```bash
sudo raspi-config --expand-rootfs
```

You will then need to reboot.  
*Note: If you have installed your SD-card using NOOBS the partition should already be extended.*

### Setup the OS for our needs

Log again in your Raspberry Pi. You can connect via ssh or directly plug a screen and a keyboard.

The following **requires the Raspberry Pi to have an internet access**.

```bash
curl -L https://raw.githubusercontent.com/poppy-project/raspoppy/master/raspoppyfication.sh -o /tmp/raspoppyfication.sh
chmod +x /tmp/raspoppyfication.sh
sudo /tmp/raspoppyfication.sh
```

These commands will install all the software detailed above, and set up the control interface. When it's done, reboot the Raspberry Pi and connect to `http://poppy.local`.

The installation script defaults will set the board for a Poppy Ergo Jr, but it can be slightly tailored to suit your needs. `./raspoppyfication.sh --help` displays available options.

Options are:

- `--creature`: Set the robot type (default: `poppy-ergo-jr`)
- `--username`: Set the Poppy user name (default: `poppy`)
- `--password`: Set password for the Poppy user (default: `poppy`)
- `--hostname`: Set the robot hostname (default: `poppy`)
- `--branch`: Install from a given git branch (default: `master`)
- `--shutdown`: Shutdowns the system after installation
- `-?|--help`: Shows help

### Shrink the ISO

Follow [these instructions](./shrink-iso.md) to reduce the size of the image. Be careful though, a bad manipulation could mess up your partitions!
