#!/usr/bin/env bash

# Using a python virtual environnement at $HOME/pyenv insted of $HOME/miniconda
# replace all "conda install" by "pip3 install"

creature=$1
hostname=$2
branch=${3:-"master"}

hampy_branch="master"

# puppet_master_branch="$branch"
viewer_branch="robot_local"
monitor_branch="master"
snap_version="5.4.5"

# v4 installation
pypot_branch="v4"
puppet_master_branch="v4"

export PATH="$HOME/pyenv/bin:$PATH"

# activate the python virtual env for all the script
# shellcheck source=./activate
source "$HOME/pyenv/bin/activate"

print_env()
{
    env
}

install_poppy_libraries()
{
    pushd /tmp || exit
        echo -e "\e[33m install_poppy_libraries: hampy \e[0m"
        wget --progress=dot:mega "https://github.com/poppy-project/hampy/archive/${hampy_branch}.zip" -O "hampy-${hampy_branch}.zip"
        pip install hampy-${hampy_branch}.zip 
        
        echo -e "\e[33m install_poppy_libraries: pypot \e[0m"
        wget --progress=dot:mega "https://github.com/poppy-project/pypot/archive/${pypot_branch}.zip" -O "pypot-$branch.zip"
        pip install "pypot-$branch.zip"
    
        echo -e "\e[33m install_poppy_libraries: $creature \e[0m"
        wget --progress=dot:mega "https://github.com/poppy-project/$creature/archive/${branch}.zip" -O "$creature-$branch.zip"
        unzip -q "$creature-$branch.zip"
        rm -f "$creature-$branch.zip"
        pushd "$creature-$branch" || exit
            pip install software/
        popd || exit
    popd || exit

    if [ -z "${POPPY_ROOT+x}" ]; then
        export POPPY_ROOT="$HOME/dev"
        echo "export POPPY_ROOT=$HOME/dev" >> "$HOME/.bashrc"
    fi
    mkdir -p "$POPPY_ROOT"

    # Symlink Poppy Python packages to allow more easily to users to view and modify the code
    for repo in pypot $creature ; do
        # Replace - to _ (I don't like regex)
        module=$(python -c "str = '$repo'; print(str.replace('-','_'))")
        module_path=$(python -c "import $module, os; print(os.path.dirname($module.__file__))")
        ln -s "$module_path" "$POPPY_ROOT"
    done
}

setup_puppet_master()
{
    echo -e "\e[33m setup_puppet_master \e[0m"
    if [ -z "${POPPY_ROOT+x}" ]; then
        export POPPY_ROOT="$HOME/dev"
        mkdir -p "$POPPY_ROOT"
    fi
    pushd "$POPPY_ROOT" || exit
        wget --progress=dot:mega "https://github.com/poppy-project/puppet-master/archive/${puppet_master_branch}.zip" -O puppet-master.zip
        unzip -q puppet-master.zip
        rm -f puppet-master.zip
        mv "puppet-master-${puppet_master_branch}" puppet-master
        pushd puppet-master || exit
            pip install flask pyyaml requests
            python bootstrap.py "$hostname" "$creature" "--branch" "${branch}"
        popd || exit
        download_documentation
        download_viewer
        download_monitor
        download_snap
        download_scratch
    popd || exit
}

# Called from setup_puppet_master()
download_monitor()
{
    echo -e "\e[33m setup_puppet_master: download_monitor \e[0m"
    wget --progress=dot:mega "https://github.com/poppy-project/poppy-monitor/archive/${monitor_branch}.zip" -O monitor.zip
    unzip -q monitor.zip
    rm -f monitor.zip
    mv "poppy-monitor-${monitor_branch}" poppy-monitor
}

# Called from setup_puppet_master()
download_viewer()
{
    echo -e "\e[33m setup_puppet_master: download_viewer \e[0m"
    wget --progress=dot:mega "https://github.com/poppy-project/poppy-simu/archive/${viewer_branch}.zip" -O viewer.zip
    unzip -q viewer.zip
    rm -f viewer.zip
    mv "poppy-simu-${viewer_branch}" poppy-viewer
}

# Called from setup_puppet_master()
download_snap()
{
    echo -e "\e[33m setup_puppet_master: download_snap \e[0m"
    wget --progress=dot:mega "https://github.com/jmoenig/Snap/archive/v${snap_version}.zip" -O snap.zip
    unzip -q snap.zip
    rm -f snap.zip
    mv "Snap-${snap_version}" snap

    #pypot_root=$(python -c "import pypot, os; print(os.path.dirname(pypot.__file__))")
    pypot_root="$POPPY_ROOT/pypot"

    # Delete snap default examples
    rm -rf snap/Examples/EXAMPLES

    # Snap projects are dynamicaly modified and copied on a local folder for acces rights issues
    # This snap_local_folder is defined depending the OS in pypot.server.snap.get_snap_user_projects_directory()
    snap_local_folder="$HOME/.local/share/pypot"
    mkdir -p "$snap_local_folder"

    # Link pypot Snap projets to Snap! Examples folder
    for project in "$pypot_root/server/snap_projects"/*.xml; do
        # Local file doesn"t exist yet if SnapRobotServer has not been started
        filename=$(basename "$project")
        cp "$project" "$snap_local_folder/"
        ln -s "$snap_local_folder/$filename" snap/Examples/
        echo -e "$filename\t$filename" >> snap/Examples/EXAMPLES
    done

    ln -s "$snap_local_folder/pypot-snap-blocks.xml" snap/libraries/poppy.xml
    echo -e "poppy.xml\tPoppy robots" >> snap/libraries/LIBRARIES
}

# Called from setup_puppet_master()
download_scratch()
{
    echo -e "\e[33m setup_puppet_master: download_scratch \e[0m"

    wget --progress=dot:mega "https://github.com/poppy-project/scratch-poppy/releases/latest/download/scratch-application.zip" -O scratch.zip
    unzip -q scratch.zip
    rm -f scratch.zip

    mv "scratch-application" "scratch"
    cat scratch/build-version.txt
}

# Called from setup_puppet_master()
download_documentation()
{
    echo -e "\e[33m setup_puppet_master: download_documentation \e[0m"
    version=$(curl --silent https://github.com/poppy-project/poppy-docs/releases/latest | sed 's#.*tag/\(.*\)\".*#\1#')
    wget --progress=dot:mega "https://github.com/poppy-project/poppy-docs/releases/download/${version}/_book.zip" -O _book.zip
    unzip -q _book.zip
    rm -rf _book.zip
    mv _book poppy-docs
    ln -s "$(realpath .)/poppy-docs/en/assembly-guides/ergo-jr" poppy-docs/en/assembly-guides/poppy-ergo-jr
    ln -s "$(realpath .)/poppy-docs/fr/assembly-guides/ergo-jr" poppy-docs/fr/assembly-guides/poppy-ergo-jr
    rm -r "poppy-docs/es" "poppy-docs/de" "poppy-docs/nl"
}

setup_documents()
{
    echo -e "\e[33m setup_documents \e[0m"
    if [ -z "${JUPYTER_FOLDER+x}" ]; then
        JUPYTER_FOLDER="$HOME/Jupyter_root"
        mkdir -p "$JUPYTER_FOLDER"
    fi
    mkdir -p "$JUPYTER_FOLDER/My Documents"
    pushd "$JUPYTER_FOLDER/My Documents" || exit
        echo -e "create symlink"

        ln -s "$POPPY_ROOT" Poppy\ Source-code
        #ln -s "$POPPY_ROOT/poppy-docs/La Documentation.pdf" La\ Documentation.pdf
        #ln -s "$POPPY_ROOT/poppy-docs/The Documentation.pdf" The\ Documentation.pdf

        mkdir -p "$POPPY_ROOT/puppet-master/moves"
        sed -i 's/self.moves_path=""/self.moves_path="moves\/"/' "$POPPY_ROOT/pypot/server/rest.py"
        sed -i 's/#os.makedirs(self.moves_path/os.makedirs(self.moves_path/g' "$POPPY_ROOT/pypot/server/rest.py"
        ln -s "$POPPY_ROOT/puppet-master/moves" Moves\ recorded

        name=$(python -c "str = '$creature'; print(str.replace('-','_'))")
        ln -s "$POPPY_ROOT/$name/primitives" Robot\ primitives
        pushd Robot\ primitives || exit
            ln -s "$POPPY_ROOT/$name/$name.py" _shortcut_to_Robot_init.py
        popd || exit

        mkdir -p "$POPPY_ROOT/puppet-master/pictures"
        sed -i 's/cv2.imwrite(\"{}.png\"/cv2.imwrite(\"pictures\/{}.png\"/' "$POPPY_ROOT/pypot/server/snap.py"
        sed -i 's/#os.makedirs(\"pictures_path\"/os.makedirs(\"pictures\"/' "$POPPY_ROOT/pypot/server/snap.py"
        ln -s "$POPPY_ROOT/puppet-master/pictures"  My\ Pictures

        echo -e "symlink done"

        get_snap_project "Snap project"
        get_notebooks "Python notebooks"
    popd || exit
}

# Called from setup_documents()
get_snap_project()
{
    echo -e "\e[33m setup_documents: get_snap_project \e[0m"
    mkdir -p "$1"
    pushd "$1" || exit
        ln -s "$POPPY_ROOT/snap/help/SnapManual.pdf" Snap\ Documentation.pdf
        ln -s "$POPPY_ROOT/snap/Examples" Snap\ codes
        mkdir -p Snap\ activities
        if [ "$creature" == "poppy-ergo-jr" ]; then
            pushd Snap\ activities || exit
                wget --progress=dot:mega https://hal.inria.fr/hal-01384649/document -O Livret\ pédagogique.pdf
                #TODO make online repo with all activities and download here
            popd || exit
        fi
    popd || exit
}

# Called from setup_documents()
get_notebooks()
{
    echo -e "\e[33m setup_documents: get_notebooks \e[0m"
    mkdir -p "$1"
    pushd "$1" || exit
        if [ "$creature" == "poppy-humanoid" ]; then
            repo=https://raw.githubusercontent.com/poppy-project/$creature/$branch
            curl -o "Motion demonstration.ipynb" "$repo/software/samples/notebooks/Demo%20Interface.ipynb"
            curl -o "Discover your Poppy Humanoid.ipynb" "$repo/software/samples/notebooks/Discover%20your%20Poppy%20Humanoid.ipynb"
            curl -o "Record, save and play moves on Poppy Humanoid.ipynb" "$repo/software/samples/notebooks/Record%2C%20Save%20and%20Play%20Moves%20on%20Poppy%20Humanoid.ipynb"
        elif [ "$creature" == "poppy-torso" ]; then
            repo=https://raw.githubusercontent.com/poppy-project/$creature/$branch/software/samples/notebooks
            curl -o "Discover your Poppy Torso.ipynb" "$repo/Discover%20your%20Poppy%20Torso.ipynb"
            curl -o "Record, save and play moves on Poppy Torso.ipynb" "$repo/Record%2C%20Save%20and%20Play%20Moves%20on%20Poppy%20Torso.ipynb"
            mkdir -p images
            pushd images || exit
              wget "$repo/images/poppy_torso.jpg" -O poppy_torso.jpg
              wget "$repo/images/poppy_torso_motors.png" -O poppy_torso_motors.png
            popd || exit
        elif [ "$creature" == "poppy-ergo-jr" ]; then
            repo=https://raw.githubusercontent.com/poppy-project/$creature/$branch/software/samples/notebooks
            curl -o "Discover your Poppy Ergo Jr.ipynb" "$repo/Discover%20your%20Poppy%20Ergo%20Jr.ipynb"
            curl -o "Record, save and play moves on Poppy Ergo Jr.ipynb" "$repo/Record%2C%20Save%20and%20Play%20Moves%20on%20Poppy%20Ergo%20Jr.ipynb"
        fi
        repo=https://raw.githubusercontent.com/poppy-project/pypot/$branch/samples/notebooks
        curl -o "Benchmark your Poppy robot.ipynb" "$repo/Benchmark%20your%20Poppy%20robot.ipynb"
        curl -o "Another language.ipynb" "$repo/Another%20language.ipynb"

        # Download community notebooks
        wget --progress=dot:mega https://github.com/poppy-project/community-notebooks/archive/master.zip -O notebooks.zip
        unzip -q notebooks.zip
        rm -f notebooks.zip
        mv community-notebooks-master community-notebooks
    popd || exit
}

setup_services()
{
    autostartup_webinterface
    autostartup_documentation
    autostartup_viewer
}
# Called from setup_service()
autostartup_webinterface()
{
    echo -e "\e[33m autostartup_webinterface \e[0m"
    cd || exit

    if [ -z "${POPPY_ROOT+x}" ]; then
        export POPPY_ROOT="$HOME/dev"
        mkdir -p "$POPPY_ROOT"
    fi

    sudo tee /etc/systemd/system/puppet-master.service > /dev/null <<EOF
[Unit]
Description=Puppet Master service
Wants=network-online.target
After=network.target network-online.target
[Service]
PIDFile=/run/puppet-master.pid
Environment="PATH=$PATH"
ExecStart=$HOME/pyenv/bin/python bouteillederouge.py
User=poppy
Group=poppy
WorkingDirectory=$POPPY_ROOT/puppet-master
Type=simple
[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable puppet-master.service
}
# Called from setup_service()
autostartup_documentation()
{
    echo -e "\e[33m autostartup_documentation \e[0m"
    cd || exit

    if [ -z "${POPPY_ROOT+x}" ]; then
        export POPPY_ROOT="$HOME/dev"
        mkdir -p "$POPPY_ROOT"
    fi

    sudo tee /etc/systemd/system/poppy-docs.service > /dev/null <<EOF
[Unit]
Description=poppy docs service
Wants=network-online.target
After=network.target network-online.target

[Service]
PIDFile=/run/poppy-docs.pid
ExecStart=$HOME/pyenv/bin/python -u -m http.server 4000
User=poppy
Group=poppy
WorkingDirectory=$POPPY_ROOT/poppy-docs/
Type=simple
StandardOutput=append:/tmp/poppy-docs.log
StandardError=append:/tmp/poppy-docs.log

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable poppy-docs.service
}
# Called from setup_service()
autostartup_viewer()
{
    echo -e "\e[33m autostartup_viewer \e[0m"
    cd || exit

    if [ -z "${POPPY_ROOT+x}" ]; then
        export POPPY_ROOT="$HOME/dev"
        mkdir -p "$POPPY_ROOT"
    fi

    sudo tee /etc/systemd/system/poppy-viewer.service > /dev/null <<EOF
[Unit]
Description=poppy viewer service
Wants=network-online.target
After=network.target network-online.target

[Service]
PIDFile=/run/poppy-viewer.pid
ExecStart=$HOME/pyenv/bin/python -u -m http.server 8000
User=poppy
Group=poppy
WorkingDirectory=$POPPY_ROOT/poppy-viewer/
Type=simple
StandardOutput=append:/tmp/poppy-viewer.log
StandardError=append:/tmp/poppy-viewer.log

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable poppy-viewer.service
}

redirect_port80_webinterface()
{
    echo -e "\e[33m redirect_port80_webinterface \e[0m"
    sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 2280
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
    sudo apt-get install -y iptables-persistent
    sudo bash -c 'iptables-save > /etc/iptables/rules.v4'
    sudo bash -c 'ip6tables-save > /etc/iptables/rules.v6'
}

setup_update()
{
    echo -e "\e[33m setup_update \e[0m"
    cd || exit
    wget "https://raw.githubusercontent.com/poppy-project/raspoppy/$branch/poppy-update.sh" -O "$HOME/.poppy-update.sh"

    cat > poppy-update << EOF
#!/$HOME/pyenv/bin/python
import os
import yaml
from subprocess import call
with open(os.path.expanduser('~/.poppy_config.yaml')) as f:
    config = yaml.load(f, Loader=yaml.SafeLoader)
with open(config['poppyLog']['update'], 'w') as f:
    call(['bash', os.path.expanduser('~/.poppy-update.sh'),
          config['info']['updateURL'],
          config['poppyLog']['update'],
          config['poppyLog']['update'].replace('.log','-pid.lock')],
          stdout=f, stderr=f)
EOF
    chmod +x poppy-update
    mv poppy-update "$HOME/pyenv/bin/"
}


set_logo()
{
    echo -e "\e[33m set_logo \e[0m"
    wget https://raw.githubusercontent.com/poppy-project/raspoppy/master/poppy_logo -O "$HOME/.poppy_logo"
    # Remove old occurences of poppy_logo in .bashrc
    sed -i /poppy_logo/d "$HOME/.bashrc"
    echo cat "$HOME/.poppy_logo" >> "$HOME/.bashrc"
}


install_poppy_libraries
setup_puppet_master
setup_documents
setup_services
redirect_port80_webinterface
setup_update
set_logo
