#!/usr/bin/env bash

username=$1
password=$2

install_custom_raspiconfig()
{
    wget https://raw.githubusercontent.com/pierre-rouanet/raspi-config/master/raspi-config
    chmod +x raspi-config
    sudo chown root:root raspi-config
    sudo mv raspi-config /usr/bin/
}


setup_user()
{
    username=$1
    password=$2

    echo -e "\e[33mCreate a user \e[4m$username\e[0m."

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
    sudo usermod -p "$(mkpasswd --method=sha-512 raspoppy)" pi

    # Add more langs (GB, US, FR)
    sudo sed -i 's/^#\s*\(en_GB.UTF-8 UTF-8\)/\1/g' /etc/locale.gen
    sudo sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/g' /etc/locale.gen
    sudo sed -i 's/^#\s*\(fr_FR.UTF-8 UTF-8\)/\1/g' /etc/locale.gengroups
    sudo locale-gen

    echo -e "\e[33mEnable camera.\e[0m"
    echo "start_x=1" | sudo tee --append /boot/config.txt
    echo "bcm2835-v4l2" | sudo tee /etc/modules-load.d/bcm2835-v4l2.conf

    echo -e "\e[33mSetup serial communication.\e[0m"
    sudo raspi-config --disable-serial-log
    sudo tee --append /boot/config.txt > /dev/null <<EOF
init_uart_clock=16000000
enable_uart=1
dtoverlay=pi3-miniuart-bt
EOF
}

install_additional_packages()
{
    sudo apt-get update

    sudo apt-get install -y \
        build-essential unzip whois \
        network-manager \
        git \
        samba samba-common avahi-autoipd avahi-utils \
        libxslt-dev

    # board version utility
    wget https://github.com/damiencaselli/hrpi-version/archive/1.0.0.zip -O hrpi-version.zip
    unzip hrpi-version.zip
    sudo mv hrpi-version-1.0.0/usr/bin/hrpi-version.sh /usr/bin/hrpi-version
    rm hrpi-version.zip
    rm -rf hrpi-version-1.0.0
}

setup_network_tools()
{
    # samba
    sudo sed -i 's/map to guest = .*/map to guest = never/g' /etc/samba/smb.conf
    (echo "poppy"; echo "poppy") | sudo smbpasswd -s -a poppy

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
  <name replace-wildcards="yes">poppy-ergo-jr on %h</name>
  <service>
    <type>_poppy-robot._tcp</type>
    <port>9</port>
  </service>
  <service>
    <type>_device-info._tcp</type>
    <port>0</port>
  </service>
  <service>
    <type>_smb._tcp</type>
    <port>445</port>
  </service>
</service-group>
EOF
}

install_custom_raspiconfig
install_additional_packages
setup_user "$username" "$password"
system_setup
setup_network_tools
