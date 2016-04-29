#!/usr/bin/env bash

creature=$1
hostname=$2

export PATH="$HOME/miniconda/bin:$PATH"

install_poppy_libraries()
{
    conda install $creature
}

install_notebooks()
{
    echo "nothing to do here..."
}

setup_puppet_master()
{
    cd || exit
    wget https://github.com/poppy-project/puppet-master/archive/master.zip
    unzip master.zip
    rm master.zip
    mv puppet-master-master puppet-master

    pushd puppet-master
        conda install flask pyyaml requests

        python bootstrap.py $hostname $creature
        install_snap "$(pwd)"
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

    cat >> puppet-master.service << EOF
[Unit]
Description=Puppet Master service

[Service]
Type=simple
ExecStart=$HOME/puppet-master/start-pwid &

[Install]
WantedBy=multi-user.target
EOF

    sudo mv puppet-master.service /lib/systemd/system/puppet-master.service

    cat >> $HOME/puppet-master/start-pwid << EOF
#!/bin/bash
su - $(whoami) -c "bash $HOME/puppet-master/launch.sh"
EOF

    cat >> $HOME/puppet-master/launch.sh << 'EOF'
export PATH=$HOME/miniconda/bin:$PATH
pushd $HOME/puppet-master
    python bouteillederouge.py 1>&2 2> /tmp/bouteillederouge.log
popd
EOF
    chmod +x $HOME/puppet-master/launch.sh $HOME/puppet-master/start-pwid

    sudo systemctl daemon-reload
    sudo systemctl enable puppet-master.service
}

redirect_port80_webinterface()
{
    cat >> firewall << EOF
#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# Flush any existing firewall rules we might have
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Perform the rewriting magic.
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to 5000
EOF
    chmod +x firewall
    sudo chown root:root firewall
    sudo mv firewall /etc/network/if-up.d/firewall
}

setup_update()
{
    cd || exit
    wget https://raw.githubusercontent.com/poppy-project/raspoppy/master/poppy-update.sh -O ~/.poppy-update.sh

    cat >> poppy-update << EOF
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

set_logo()
{
    wget -P  /home https://raw.githubusercontent.com/poppy-project/raspoppy/master/poppy_logo
    sed -i /poppy_logo/d /home/poppy/.bashrc
    echo cat /home/poppy_logo >> /home/poppy/.bashrc
}

install_poppy_libraries
install_notebooks
setup_puppet_master
autostartup_webinterface
redirect_port80_webinterface
setup_update
set_logo
