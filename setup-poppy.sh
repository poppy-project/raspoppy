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
        if [ "$creatures" == "poppy-torso" ]; then
          curl -o "Discover your Poppy Torso.ipynb" https://raw.githubusercontent.com/poppy-project/poppy-torso/master/software/samples/notebooks/Discover%20your%20Poppy%20Torso.ipynb
          curl -o "Record, save and play moves on Poppy Torso.ipynb" https://raw.githubusercontent.com/poppy-project/poppy-torso/master/software/samples/notebooks/Record%2C%20Save%20and%20Play%20Moves%20on%20Poppy%20Torso.ipynb

          mkdir -p images
          pushd images
            wget https://raw.githubusercontent.com/poppy-project/poppy-torso/master/software/samples/notebooks/images/poppy_torso.jpg -O poppy_torso.jpg
            wget https://raw.githubusercontent.com/poppy-project/poppy-torso/master/software/samples/notebooks/images/poppy_torso_motors.png -O poppy_torso_motors.png
          popd
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

        ln -s $POPPY_ROOT poppy_src
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

# Called from setup_puppet_master()
install_snap()
{
    pushd $1
        wget https://github.com/jmoenig/Snap--Build-Your-Own-Blocks/archive/master.zip -O master.zip
        unzip master.zip
        rm master.zip
        mv Snap--Build-Your-Own-Blocks-master snap

        pypot_root=$(python -c "import pypot, os; print(os.path.dirname(pypot.__file__))")

        # Delete snap default examples
        rm snap/Examples/EXAMPLES

        # Snap projects are dynamicaly modified and copied on a local folder for acces rights issues
        # This snap_local_folder is defined depending the OS in pypot.server.snap.get_snap_user_projects_directory()
        snap_local_folder="$HOME/.local/share/pypot"
        mkdir -p "$snap_local_folder"

        # Link pypot Snap projets to Snap! Examples folder
        for project in $pypot_root/server/snap_projects/*.xml; do
            # Local file doesn"t exist yet if SnapRobotServer has not been started
            filename=$(basename "$project")
            cp $project $snap_local_folder/
            ln -s $snap_local_folder/$filename snap/Examples/

            echo -e "$filename\t$filename" >> snap/Examples/EXAMPLES
        done


        ln -s $snap_local_folder/pypot-snap-blocks.xml snap/libraries/poppy.xml
        echo -e "poppy.xml\tPoppy robots" >> snap/libraries/LIBRARIES


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

    sudo tee /etc/systemd/system/puppet-master.service > /dev/null <<EOF
[Unit]
Description=Puppet Master service
Wants=network-online.target
After=network.target network-online.target

[Service]
PIDFile=/var/run/puppet-master.pid
Environment="PATH=$HOME/miniconda/bin"
ExecStart=$HOME/miniconda/bin/python bouteillederouge.py
User=poppy
Group=poppy
WorkingDirectory=$POPPY_ROOT/puppet-master
Type=simple

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable puppet-master.service
}

redirect_port80_webinterface()
{
    sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to 2280
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
    sudo apt-get install -y --force-yes iptables-persistent
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
autostartup_webinterface
redirect_port80_webinterface
setup_update
set_logo
