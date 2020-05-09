#!/bin/bash

# modified by JLC to use rpi3-4-hotspot.zip for Rapbian-buster :

git_branch=$1

cd /tmp || exit
wget -O rpi3-hotspot.zip "https://github.com/poppy-project/puppet-master/archive/${git_branch}.zip"
unzip rpi3-hotspot.zip
rm -f rpi3-hotspot.zip
mv rpi3-hotspot-* rpi3-hotspot
cd rpi3-hotspot || exit
./install.sh
cd /tmp || exit
rm -rf rpi3-hotspot

tee /boot/hotspot.txt <<EOF
ssid=Poppy Hotspot
passphrase=poppyproject
EOF

