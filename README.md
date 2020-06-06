
# Raspoppy: Utility tools to setup a Raspberry Pi for Poppy robots

This repository regroups the set of tools we use to setup a Raspberry Pi board for a Poppy robot.

While we try to keep this procedure as simple as possible, it still requires a good knowledge of Linux OS and of Python. For those who are not interested in digging into those details, we provide ready-to-use SD-card images which can be directly downloaded and copy into your Raspberry.

## Update

## Manual install

### Install Raspbian

Download [the latest Raspberry Pi OS (32-bit) with desktop](https://downloads.raspberrypi.org/raspios_armhf_latest) and follow [the installing guide](https://www.raspberrypi.org/documentation/installation/installing-images/README.md). We used **2020-05-27-raspios-buster-armhf.img**. 

### Setup the OS for our needs

Boot your system and temporarily connect a HDMI monitor, and an Ethernet cable to your router. In order to raspoppyfy your Raspberry Pi, it is needed that **the Raspberry Pi has an internet access**.

Then open the terminal and type these commands:

```bash
curl -L https://raw.githubusercontent.com/poppy-project/raspoppy/dev_gen2/raspoppyfication.sh -o /tmp/raspoppyfication.sh
chmod +x /tmp/raspoppyfication.sh
sudo /tmp/raspoppyfication.sh --branch=dev_gen2 | tee $HOME/log_raspoppy_$(date +%F_%H-%M).txt
```

They will install all the software detailed above, and set up the control interface. When it's done, reboot the Raspberry Pi and connect to `http://poppy.local`.

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
