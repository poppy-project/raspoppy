#!/usr/bin/env bash
 
#version modified by JLC for RPi4 2020/02/13

git_branch=$1

create_virtual_python_env()
{
    echo -e "\e[33m Creating a virtual python env for $USER in $HOME/pyenv \e[0m"
    if [ -d "$HOME/pyenv" ]; then
	    echo -e "\tvirtual python env already exists in $HOME/pyenv"
    else
	    python3 -m venv $HOME/pyenv
    fi
    #JLC: activate python environnement pyenv in poppy's .bashrc:
    if ! grep -q '^source $HOME/pyenv/bin/activate$' $HOME/.bashrc; then
    	echo "activating pyenv in poppy .bashrc"
    	echo 'source $HOME/pyenv/bin/activate' >> $HOME/.bashrc
    fi
}

install_python_packages()
{
    echo -e "\e[33m install_python_packages \e[0m"
    source $HOME/pyenv/bin/activate && pip install \
        numpy scipy==1.3.1 pyzmq==17.1 jupyter matplotlib explauto wheel pillow opencv-python-headless
}

configure_jupyter()
{
    echo -e "\e[33m configure_jupyter \e[0m"
    JUPYTER_CONFIG_FILE=$HOME/.jupyter/jupyter_notebook_config.py
    export JUPYTER_FOLDER=$HOME/Jupyter_root

    echo -e "set Jupyter folder to $JUPYTER_FOLDER"
    mkdir -p "$JUPYTER_FOLDER"

    source $HOME/pyenv/bin/activate && jupyter notebook --generate-config --y

    cat >> "$JUPYTER_CONFIG_FILE" <<EOF
# --- Poppy configuration ---
c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '$JUPYTER_FOLDER'
c.NotebookApp.tornado_settings = {'headers': {'Content-Security-Policy': "frame-ancestors 'self' *"}}
c.NotebookApp.allow_origin = '*'
c.NotebookApp.extra_static_paths = ["static/custom/custom.js"]
c.NotebookApp.token = ''
c.NotebookApp.password = ''
# --- Poppy configuration ---
EOF

    JUPYTER_CUSTOM_JS_FILE=$HOME/.jupyter/custom/custom.js
    mkdir -p "$HOME/.jupyter/custom"
    cat > "$JUPYTER_CUSTOM_JS_FILE" <<EOF
/* Allow new tab to be openned in an iframe */
define(['base/js/namespace'], function(Jupyter){
  Jupyter._target = '_self';
})
EOF

    source $HOME/pyenv/bin/activate python -c """
import os
from jupyter_core.paths import jupyter_data_dir
d = jupyter_data_dir()
if not os.path.exists(d):
    os.makedirs(d)
"""
    pushd /tmp
        wget --progress=dot:mega https://github.com/ipython-contrib/IPython-notebook-extensions/archive/master.zip -O master.zip
	source $HOME/pyenv/bin/activate pip install master.zip
    popd
}

autostart_jupyter()
{
    echo -e "\e[33m autostart_jupyter \e[0m"
    sudo tee /etc/systemd/system/jupyter-notebook.service > /dev/null <<EOF
[Unit]
Description=Jupyter notebook
Wants=network-online.target
After=network.target network-online.target
[Service]
PIDFile=/run/jupyter-notebook.pid
Environment="PATH=$PATH"
ExecStart=$HOME/pyenv/bin/jupyter notebook
User=poppy
Group=poppy
WorkingDirectory=$JUPYTER_FOLDER
Type=simple
StandardOutput=append:/tmp/jupyter.log
StandardError=append:/tmp/jupyter.log
[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable jupyter-notebook.service
}

create_virtual_python_env
install_python_packages
configure_jupyter
autostart_jupyter

