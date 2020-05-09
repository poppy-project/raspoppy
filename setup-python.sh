#!/usr/bin/env bash
 
#version modified by JLC for RPi4 2020/02/13

git_branch=$1

create_virtual_python_env()
{
    echo "creating a virtual python env for $USER in $HOME/pyenv"
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
    source $HOME/pyenv/bin/activate && pip install \
    	numpy scipy==1.3.1 jupyter matplotlib explauto wheel pillow \
    	opencv-contrib-python==4.1.0.25 
}

configure_jupyter()
{
    JUPYTER_CONFIG_FILE=$HOME/.jupyter/jupyter_notebook_config.py
    export JUPTER_NOTEBOOK_FOLDER=$HOME/notebooks

    mkdir -p "$JUPTER_NOTEBOOK_FOLDER"

    source $HOME/pyenv/bin/activate && jupyter notebook --generate-config --y

    cat >> "$JUPYTER_CONFIG_FILE" <<EOF
# --- Poppy configuration ---
c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '$JUPTER_NOTEBOOK_FOLDER'
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

    source $HOME/pyenv/bin/activate && python -c """
import os
from jupyter_core.paths import jupyter_data_dir
d = jupyter_data_dir()
if not os.path.exists(d):
    os.makedirs(d)
"""

    source $HOME/pyenv/bin/activate && pip install https://github.com/ipython-contrib/IPython-notebook-extensions/archive/master.zip
}

autostart_jupyter()
{
    sudo tee /etc/systemd/system/jupyter-notebook.service > /dev/null <<EOF
[Unit]
Description=Jupyter notebook
Wants=network-online.target
After=network.target network-online.target
[Service]
PIDFile=/run/jupyter-notebook.pid
Environment="PATH=$PATH"
ExecStart=source $HOME/pyenv/bin/activate && jupyter notebook
User=poppy
Group=poppy
WorkingDirectory=$JUPTER_NOTEBOOK_FOLDER
Type=simple
[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable jupyter-notebook.service
}

create_virtual_python_env
install_python_packages
configure_jupyter
autostart_jupyter

