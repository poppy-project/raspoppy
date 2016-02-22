# Raspoppy: Utility tools to setup a RaspberryPi-2 for Poppy robots

This repository regroups the set of tools we use to setup a Raspberry board for a Poppy robot.

While we try to keep this procedure as simple as possible, it still requires a good knowledge of Linux OS and of Python. For those who are not interested in digging into those details, we provide ready-to-use SD-card images which  can be directly downloaded and copy in your Raspberry.

*While this procedure is mainly designed for the Raspberypi-2, most of it (especially all conda recipes) should also work for the odroid XU4 as both boards used an armv7 CPU. It is important to also note that this procedure is only given as an example: i.e. this is how we build the SD-card images we provide. Yet, you can freely adapt to better match your needs.*

## Current SD card ISO version: 1.0

* [ ] Default user: poppy password: poppy
* [ ] Default hostname: poppy
* [ ] Python 2.7.10 [miniconda latest - 3.18.3](http://repo.continuum.io/miniconda/Miniconda3-3.18.3-Linux-armv7l.sh) distribution for linux-armv7
* [ ] Conda recipes for linux-armv7 (on the [poppy-project](https://anaconda.org/poppy-project/) channel):
    * [x] numpy 1.9.2
    * [x] scipy 0.16.0 (need libopenblas-dev)
    * [x] opencv 3.1.0
    * [ ] jupyter
    * [ ] matplotlib
    * [ ] pypot
    * [ ] poppy-creatures
    * [ ] poppy-humanoid
    * [ ] poppy-torso
    * [ ] poppy-ergo-jr
    * [x] hampy 1.4.1
    * [x] aupyom 0.1.0 (need libportaudio-dev)
    * [x] explauto 1.2.0
* [ ] jupyter extensions
* [ ] auto start jupyter at boot?
* [ ] RPI-camera enabled
* [ ] setup serial communication
* [ ] resize to full card on first boot
* [ ] Interface web + web apps (wifi & hostname)
* [ ] Snap!
* [ ] add custom sounds
* [ ] add ssh public keys

## Update

## Manual install

### Install Raspbian

Just follow standard [instructions](https://www.raspberrypi.org/downloads/raspbian/) from raspberry.org. We use the latest lite Raspbian image.

*Note: the rest of the procedure will require to have an internet access on the Raspberry.*


* run system script (as root)
* reboot
* run poppy script (as poppy)
