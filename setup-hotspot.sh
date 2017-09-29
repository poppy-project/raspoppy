#!/bin/bash

if [ "$(hrpi-version)" = "rpi-3" ]; then
    poppy_hostname="$1"

    cd /tmp || exit
    wget -O rpi3-hotspot.zip "https://gitlab.inria.fr/dcaselli/rpi3-hotspot/repository/archive.zip?ref=2.0.1"
    unzip rpi3-hotspot.zip
    rm rpi3-hotspot.zip
    mv rpi3-hotspot* rpi3-hotspot
    cd rpi3-hotspot || exit
    ./install.sh
    rm -rf rpi3-hotspot

    tee /boot/hotspot.txt <<EOF
ssid=Poppy Hotspot for $poppy_hostname
passphrase=poppyproject
EOF
fi
