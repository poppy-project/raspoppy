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

    pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
    sudo useradd -m -p $pass $username

    # copy groups from pi user
    G=`groups pi | cut -f2 -d':'`
    G=`echo ${G} | sed 's/ /,/g'`
    sudo usermod -a -G $G $username

    echo "$username ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/011_poppy-nopasswd
}

system_setup()
{
    # Change password for pi user
    sudo usermod -p "$(mkpasswd --method=sha-512 raspoppy)" pi

    # Add more langs (GB, US, FR)
    sudo sed -i 's/^#\s*\(en_GB.UTF-8 UTF-8\)/\1/g' /etc/locale.gen
    sudo sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/g' /etc/locale.gen
    sudo sed -i 's/^#\s*\(fr_FR.UTF-8 UTF-8\)/\1/g' /etc/locale.gen
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

    sudo apt-get install build-essential unzip

    # Used for being able to change hostname without reboot
    sudo apt-get install -y --force-yes network-manager

    sudo apt-get install -y --force-yes git

    # Connectivity
    sudo apt-get install -y --force-yes samba samba-common avahi-autoipd avahi-utils

    # board version utility
    wget https://github.com/damiencaselli/hrpi-version/archive/1.0.0.zip -O hrpi-version.zip
    unzip hrpi-version.zip
    mv hrpi-version-1.0.0/usr/bin/hrpi-version.sh /usr/bin/hrpi-version
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

setup_hotspot()
{
    apt-get install -y hostapd dnsmasq
    systemctl disable hostapd
    systemctl disable dnsmasq
    tee /etc/hostapd/hostapd.conf > /dev/null <<EOF
interface=wlan0
driver=nl80211
ssid=PoppyHotspot
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=poppyproject
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

    tee --append /etc/default/hostapd > /dev/null <<EOF

# Added by Poppy script
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

    tee --append /etc/dnsmasq.conf > /dev/null <<EOF

# Added by Poppy script
# Hotspot configuration
no-resolv
interface=wlan0
bind-interfaces
dhcp-range=192.168.0.3,192.168.0.20,12h
EOF

    sed -i 's/^auto lo$/auto lo wlan0/g' /etc/network/interfaces
    sed -i '/iface wlan0 inet manual/{N;N;s/wpa-conf/# wpa-conf/}' /etc/network/interfaces

    tee /usr/bin/rpi-hotspot > /dev/null <<'EOF'
#!/bin/bash
#

if [ -f /boot/hotspot.txt ]; then
  hotspot_ssid=$(sed -n -e 's/^ssid=\([[:alnum:]]\+\)/\1/p' /boot/hotspot.txt)
  hotspot_ssid="${hotspot_ssid:-PoppyHotspot}"
  hotspot_passphrase=$(sed -n -e 's/^passphrase=\([[:alnum:]]\+\)/\1/p' /boot/hotspot.txt)
  hotspot_passphrase="${hotspot_passphrase:-poppyproject}"

  sed -i "s/ssid=.*/ssid=$hotspot_ssid/g" /etc/hostapd/hostapd.conf
  sed -i "s/passphrase=.*/passphrase=$hotspot_passphrase/g" /etc/hostapd/hostapd.conf

  ip link set dev wlan0 down
  ip a add 192.168.0.1/24 dev wlan0
  ip link set dev wlan0 up
  systemctl start dnsmasq
  systemctl start hostapd
else
  wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null 2>&1
fi
EOF

    chmod +x /usr/bin/rpi-hotspot

    tee /etc/systemd/system/rpi-hotspot.service > /dev/null <<EOF
[Unit]
Description=Generates a hotspot
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/rpi-hotspot

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable rpi-hotspot.service
}

install_custom_raspiconfig
setup_user $username $password
install_additional_packages
system_setup
setup_network_tools

if [ "$(hrpi-version)" = "rpi-3" ]; then
    setup_hotspot
fi
