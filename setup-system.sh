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
    echo -e "\e[33mEnable camera.\e[0m"
    sudo raspi-config --enable-camera
    echo "bcm2835-v4l2" | sudo tee -a /etc/modules

    echo -e "\e[33mSetup serial communication.\e[0m"
    sudo raspi-config --disable-serial-log
    sudo su -c "echo \"init_uart_clock=16000000\" >> /boot/config.txt"
}

install_additional_packages()
{
    sudo apt-get update

    # Used for being able to change hostname without reboot
    sudo apt-get install -y --force-yes network-manager 

    sudo apt-get install -y --force-yes git

    # Allow direct ethernet connection without router or network sharing -> IP4LL protocol
    sudo apt-get install -y --force-yes avahi-autoipd avahi-daemon
}


autostart_zeroconf_poppy_publisher()
{
    cat > poppy-publisher.service << EOF
[Unit]
Description=Poppy Zeroconf publisher

[Service]
Type=simple
ExecStart=/usr/bin/avahi-publish -s $HOSTNAME _poppy_robot._tcp 9 &

[Install]
WantedBy=multi-user.target
EOF

    sudo mv poppy-publisher.service /lib/systemd/system/poppy-publisher.service
    sudo systemctl daemon-reload
    sudo systemctl enable poppy-publisher.service
     
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
autostart_zeroconf_poppy_publisher
install_git_lfs