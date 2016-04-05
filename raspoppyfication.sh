#!/usr/bin/env bash

creature=$1
creature="poppy-ergo-jr"

username="poppy"
password="poppy"
hostname="poppy"

url_root="https://raw.githubusercontent.com/pierre-rouanet/raspoppy/master"

cd /tmp || exit
wget $url_root/setup-system.sh
bash setup-system.sh $username $password

wget $url_root/setup-python.sh
sudo -u $username bash setup-python.sh

wget $url_root/setup-poppy.sh
sudo -u $username bash setup-poppy.sh $creature $hostname

echo -e "\e[33mChange hostname to \e[4m$hostname.\e[0m"
sudo raspi-config --change-hostname $hostname
