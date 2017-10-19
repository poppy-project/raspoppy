#!/bin/bash

if [ "$(hrpi-version)" = "rpi-3" ]; then
    cd /tmp || exit
    wget -O rpi3-hotspot.zip "https://gitlab.inria.fr/dcaselli/rpi3-hotspot/repository/archive.zip?ref=3.0.0"
    unzip rpi3-hotspot.zip
    rm rpi3-hotspot.zip
    mv rpi3-hotspot* rpi3-hotspot
    cd rpi3-hotspot || exit
    ./install.sh
    cd /tmp || exit
    rm -rf rpi3-hotspot

    tee /boot/hotspot.txt <<EOF
ssid=Poppy Hotspot
passphrase=poppyproject
EOF
fi
