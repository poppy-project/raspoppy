#!/usr/bin/env bash

creature=$1
hostname=$2

export PATH="$HOME/miniconda/bin:$PATH"

install_poppy_libraries()
{
    conda install $creature


    if [ -z ${POPPY_ROOT+x} ]; then
        export POPPY_ROOT="$HOME/dev"
        echo 'export POPPY_ROOT="$HOME/dev" >> ~/.bashrc'
    fi
    mkdir -p "$POPPY_ROOT"

    # Symlink Poppy Python packages to allow more easily to users to view and modify the code
    for repo in pypot $creature ; do
        # Replace - to _ (I don't like regex)
        module=`python -c 'str = "'$repo'" ; print str.replace("-","_")'`

        module_path=`python -c 'import '$module', os; print os.path.dirname('$module'.__file__)'`
        ln -s "$module_path" "$POPPY_ROOT"
    done
}

populate_notebooks()
{
    if [ -z ${JUPTER_NOTEBOOK_FOLDER+x} ]; then
        JUPTER_NOTEBOOK_FOLDER="$HOME/notebooks"
    fi
    mkdir -p "$JUPTER_NOTEBOOK_FOLDER"

    pushd $JUPTER_NOTEBOOK_FOLDER

        if [ "$creature" == "poppy-humanoid" ]; then
            curl -o Demo_interface.ipynb https://raw.githubusercontent.com/poppy-project/poppy-humanoid/master/software/samples/notebooks/Demo%20Interface.ipynb
        fi
        if [ "$creature" == "poppy-ergo-jr" ]; then
            curl -o "Discover your Poppy Ergo Jr.ipynb" https://raw.githubusercontent.com/poppy-project/poppy-ergo-jr/master/software/samples/notebooks/Discover%20your%20Poppy%20Ergo%20Jr.ipynb
            curl -o "Record, save and play moves on Poppy Ergo Jr.ipynb" https://raw.githubusercontent.com/poppy-project/poppy-ergo-jr/master/software/samples/notebooks/Record%2C%20Save%20and%20Play%20Moves%20on%20Poppy%20Ergo%20Jr.ipynb
        fi

        curl -o "Benchmark your Poppy robot.ipynb" https://raw.githubusercontent.com/poppy-project/pypot/master/samples/notebooks/Benchmark%20your%20Poppy%20robot.ipynb

        # Download community notebooks
        wget https://github.com/poppy-project/community-notebooks/archive/master.zip -O master.zip
        unzip master.zip
        mv community-notebooks-master community-notebooks
        rm master.zip

        # Copy the documentation pdf
        wget https://www.gitbook.com/download/pdf/book/poppy-project/poppy-docs?lang=en -O documentation.pdf
    popd
}

setup_puppet_master()
{
    if [ -z ${POPPY_ROOT+x} ]; then
        export POPPY_ROOT="$HOME/dev"
        mkdir -p $POPPY_ROOT
    fi

    pushd "$POPPY_ROOT"
        wget https://github.com/poppy-project/puppet-master/archive/master.zip
        unzip master.zip
        rm master.zip
        mv puppet-master-master puppet-master

        pushd puppet-master
            conda install flask pyyaml requests

            python bootstrap.py $hostname $creature
            install_snap "$(pwd)"
        popd
    popd
}

install_snap()
{
    pushd $1
        wget https://github.com/jmoenig/Snap--Build-Your-Own-Blocks/archive/master.zip -O master.zip
        unzip master.zip
        rm master.zip
        mv Snap--Build-Your-Own-Blocks-master snap

        pypot_root=$(python -c "import pypot, os; print(os.path.dirname(pypot.__file__))")
        ln -s $pypot_root/server/snap_projects/pypot-snap-blocks.xml snap/libraries/poppy.xml
        echo -e "poppy.xml\tPoppy robots" >> snap/libraries/LIBRARIES

        # Delete snap default examples
        rm snap/Examples/EXAMPLES

        # Link pypot Snap projets to Snap! Examples folder
        for project in $pypot_root/server/snap_projects/*.xml; do
            ln -s $project snap/Examples/

            filename=$(basename "$project")
            echo -e "$filename\tPoppy robots" >> snap/Examples/EXAMPLES
        done

        wget https://github.com/poppy-project/poppy-monitor/archive/master.zip -O master.zip
        unzip master.zip
        rm master.zip
        mv poppy-monitor-master monitor
    popd
}

autostartup_webinterface()
{
    cd || exit

    if [ -z ${POPPY_ROOT+x} ]; then
        export POPPY_ROOT="$HOME/dev"
        mkdir -p $POPPY_ROOT

    fi

    cat > puppet-master.service << EOF
[Unit]
Description=Puppet Master service

[Service]
Type=simple
ExecStart=$POPPY_ROOT/puppet-master/start-pwid &

[Install]
WantedBy=multi-user.target
EOF

    sudo mv puppet-master.service /lib/systemd/system/puppet-master.service

    cat > $POPPY_ROOT/puppet-master/start-pwid << EOF
#!/bin/bash
su - $(whoami) -c "bash $POPPY_ROOT/puppet-master/launch.sh"
EOF

    cat > $POPPY_ROOT/puppet-master/launch.sh << EOF
export PATH=$HOME/miniconda/bin:$PATH

pushd $POPPY_ROOT/puppet-master
    python bouteillederouge.py 1>&2 2> /tmp/bouteillederouge.log
popd
EOF
    chmod +x $POPPY_ROOT/puppet-master/launch.sh $POPPY_ROOT/puppet-master/start-pwid

    sudo systemctl daemon-reload
    sudo systemctl enable puppet-master.service
}

redirect_port80_webinterface()
{
    cat > firewall << EOF
#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# Flush any existing firewall rules we might have
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Perform the rewriting magic.
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to 2280
EOF
    chmod +x firewall
    sudo chown root:root firewall
    sudo mv firewall /etc/network/if-up.d/firewall
}

setup_update()
{
    cd || exit
    wget https://raw.githubusercontent.com/poppy-project/raspoppy/master/poppy-update.sh -O ~/.poppy-update.sh

    cat > poppy-update << EOF
#!/usr/bin/env python

import os
import yaml

from subprocess import call


with open(os.path.expanduser('~/.poppy_config.yaml')) as f:
    config = yaml.load(f)


with open(config['update']['logfile'], 'w') as f:
    call(['bash', os.path.expanduser('~/.poppy-update.sh'),
          config['update']['url'],
          config['update']['logfile'],
          config['update']['lockfile']], stdout=f, stderr=f)
EOF
    chmod +x poppy-update
    mv poppy-update $HOME/miniconda/bin/
}

install_git_lfs()
{
    set -e
    # Get out if git-lfs is already installed
    if $(git-lfs &> /dev/null); then
        echo "git-lfs is already installed"
        return
    fi

    # Install go 1.6 for ARMv6 (works also on ARMv7 & ARMv8)
    sudo apt-get --yes --force-yes install git
    mkdir -p $POPPY_ROOT/go
    pushd "$POPPY_ROOT/go"
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
              sudo cp bin/git-lfs /usr/bin/
            popd
        popd
    popd
    hash -r
    git lfs install
    set +e
}


set_logo()
{
    wget https://raw.githubusercontent.com/poppy-project/raspoppy/master/poppy_logo -O $HOME/.poppy_logo
    # Remove old occurences of poppy_logo in .bashrc
    sed -i /poppy_logo/d $HOME/.bashrc
    echo cat $HOME/.poppy_logo >> $HOME/.bashrc
}

install_poppy_libraries
populate_notebooks
setup_puppet_master
install_snap
autostartup_webinterface
redirect_port80_webinterface
setup_update
install_git_lfs
set_logo
