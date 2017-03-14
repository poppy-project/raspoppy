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

    echo "$username ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
}

system_setup()
{
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
}


setup_network_tools()
{
    # samba
    sudo sed -i 's/map to guest = .*/map to guest = never/g' /etc/samba/smb.conf
    (echo "poppy"; echo "poppy") | sudo smbpasswd -s -a poppy

    # avahi services
    sudo cat <<EOF >> /etc/avahi/services/ssh.service
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

    sudo cat <<EOF >> /etc/avahi/services/poppy.service
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

install_git_lfs()
{
    set -e
    # Get out if git-lfs is already installed
    if $(git-lfs &> /dev/null); then
        echo "git-lfs is already installed"
        return
    fi

    GIT_LFS_BUILD=$HOME/.bin
    # Install go 1.6 for ARMv6 (works also on ARMv7 & ARMv8)
    sudo apt-get --yes --force-yes install git
    mkdir -p $GIT_LFS_BUILD/go
    pushd "$GIT_LFS_BUILD/go"
        wget https://storage.googleapis.com/golang/go1.6.2.linux-armv6l.tar.gz -O go.tar.gz
        sudo tar -C /usr/local -xzf go.tar.gz
        rm go.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        export GOPATH=$PWD
        echo "PATH=$PATH:/usr/local/go/bin" >> $HOME/.bashrc
        echo "GOPATH=$PWD" >> $HOME/.bashrc

        # Download and compile git-lfs
        mkdir -p src/github.com/github
        pushd src/github.com/github
            git clone https://github.com/github/git-lfs
            pushd git-lfs
              script/bootstrap
              sudo mv bin/git-lfs /usr/bin/
            popd
        popd
    popd
    hash -r
    git lfs install
    set +e
}



install_custom_raspiconfig
setup_user $username $password
install_additional_packages
system_setup
setup_network_tools
install_git_lfs
