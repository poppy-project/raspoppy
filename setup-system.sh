#!/usr/bin/env bash

# 2020/02/13 version modified by JLC for Raspbian buster & RPi4 
#
# use $(hrpi-version) to do conditional process for rpi-3, rpi-4 and buster
# install_custom_raspiconfig() only for RPi3

username=$1
password=$2
creature=$3
git_branch=${4:-"master"}

install_custom_raspiconfig()
{
    echo -e "\e[33m install_custom_raspiconfig \e[0m"
    wget https://raw.githubusercontent.com/poppy-project/raspi-config/master/raspi-config
    chmod +x raspi-config
    sudo chown root:root raspi-config
    sudo mv raspi-config /usr/bin/
}

setup_user()
{
    username=$1
    password=$2

    echo -e "\e[33m Create a user \e[4m$username\e[0m"

    pass=$(perl -e 'print crypt($ARGV[0], "password")' "$password")
    sudo useradd -m -p "$pass" -s /bin/bash "$username"

    # copy groups from pi user
    user_groups=$(id -Gn pi)
    user_groups=${user_groups// /,}
    sudo usermod -a -G "$user_groups" "$username"

    echo "$username ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/011_poppy-nopasswd
}

system_setup()
{
    # Change password for pi user
    echo -e "\e[33m Change password for pi user \e[0m"
    sudo usermod -p "$(mkpasswd --method=sha-512 raspoppy)" pi

    #enable ssh
    echo -e "\e[33m Enable ssh communication \e[0m"
    sudo systemctl enable ssh

    # Add more langs (GB, US, FR)
    sudo sed -i 's/^#\s*\(en_GB.UTF-8 UTF-8\)/\1/g' /etc/locale.gen
    sudo sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/g' /etc/locale.gen
    sudo sed -i 's/^#\s*\(fr_FR.UTF-8 UTF-8\)/\1/g' /etc/locale.gen
    sudo locale-gen

    
    if [ "$creature" = "poppy-ergo-jr" ]; then
        echo -e "\e[33m Enable camera \e[0m"
        echo "start_x=1" | sudo tee --append /boot/config.txt
        echo "bcm2835-v4l2" | sudo tee /etc/modules-load.d/bcm2835-v4l2.conf

        echo -e "\e[33m Setup serial communication \e[0m"
        sudo raspi-config --disable-serial-log

        #JLC: don't know if the stuff bellow must be done with RPi4 under RaspBian buster ?
	if [ "$(hrpi-version)" != "rpi-4" ]; then
            sudo tee --append /boot/config.txt > /dev/null <<EOF
init_uart_clock=16000000
dtoverlay=pi3-miniuart-bt
EOF
        fi
     fi
}

install_additional_packages()
{
    echo -e "\e[33m upgrade_system \e[0m"
    sudo apt-get update && sudo apt upgrade -y && sudo apt autoremove -y    
    # added python3-venev & libatalas-base-dev for RaspBian buster:
    # removed samba* & dhcpcd, added libhdf5-dev libhdf5-serial-dev libjasper-dev for opencv
    echo -e "\e[33m install_additional_packages \e[0m"
    sudo apt-get install -y \
        build-essential unzip whois \
        network-manager git avahi-autoipd avahi-utils \
        libxslt-dev python3-venv libatlas-base-dev \
        libhdf5-dev libhdf5-serial-dev libjasper-dev libqtgui4 libqt4-test

    # board version utility
    # hrpi-version compatible with rpi-3 & rpi-4 is replaced by the new version included in the depository
    echo -e "\e[33m board_version_utility \e[0m"
    wget https://raw.githubusercontent.com/poppy-project/raspoppy/${git_branch}/hrpi-version.sh -O hrpi-version.sh
    sudo cp hrpi-version.sh /usr/bin/hrpi-version
    sudo chmod +x /usr/bin/hrpi-version
}

setup_network_tools()
{
    echo -e "\e[33m setup_network_tools \e[0m"

# avahi services
    sudo tee /etc/avahi/services/ssh.service <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">SSH on %h</name>
  <service>
    <type>_ssh._tcp</type>
    <port>22</port>
  </service>
  <service>
    <type>_sftp-ssh._tcp</type>
    <port>22</port>
  </service>
</service-group>
EOF

    sudo tee /etc/avahi/services/poppy.service <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">poppy on %h</name>
  <service>
    <type>_poppy-robot._tcp</type>
    <port>9</port>
  </service>
  <service>
    <type>_device-info._tcp</type>
    <port>0</port>
  </service>
</service-group>
EOF
}

setup_desktop()
{
username=$1

# Disable some verbose logs at boot
sudo tee --append /boot/config.txt >/dev/null <<< "disable_splash=1"
sudo sed -i 's/console=tty1/console=tty3 logo.nologo vt.global_cursor_default=0/g' /boot/cmdline.txt

# Put some Poppy images
sudo mv splash.png /usr/share/plymouth/themes/pix/splash.png
sudo mv wallpaper.jpg /usr/share/rpd-wallpaper/temple.jpg
sudo mv icon.png /usr/share/icons/poppy.png

# Desktop autologin with username
sudo sed -i "s/# autologin-user = /autologin-user=$username   #/g" /etc/lightdm/lightdm.conf

# Setup a Poppy Manager desktop entry
sudo -u "$username" mkdir -p "/home/$username/.local/share/applications/"
sudo -u "$username" tee "/home/$username/.local/share/applications/poppy.desktop" > /dev/null <<EOF
[Desktop Entry]
Encoding=UTF-8
Name=Poppy Manager
Icon=poppy
Type=Application
Categories=Office;
Exec=xdg-open http://poppy.local/
EOF
}

# install_additional_packages is run first to make hrpi-version available:
install_additional_packages
install_custom_raspiconfig
setup_user "$username" "$password"
setup_desktop "$username"
system_setup
setup_network_tools

