#!/usr/bin/env bash

install_conda()
{
    cd || exit
    wget http://repo.continuum.io/miniconda/Miniconda-latest-Linux-armv7l.sh -O Miniconda-latest-Linux-armv7l.sh
    bash Miniconda-latest-Linux-armv7l.sh -b
    rm Miniconda-latest-Linux-armv7l.sh

    echo 'export PATH=$HOME/miniconda/bin:$PATH' >> "$HOME/.bashrc"
    export PATH="$HOME/miniconda/bin:$PATH"

    conda config --add channels poppy-project
    conda config --set show_channel_urls True
    conda config --set always_yes yes --set changeps1 no

    conda update conda
}

install_python_packages()
{
    conda install numpy scipy jupyter matplotlib explauto
}

configure_jupyter()
{
    JUPYTER_CONFIG_FILE=$HOME/.jupyter/jupyter_notebook_config.py
    export JUPTER_NOTEBOOK_FOLDER=$HOME/notebooks

    mkdir -p "$JUPTER_NOTEBOOK_FOLDER"

    yes | jupyter notebook --generate-config

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

    python -c """
import os

from jupyter_core.paths import jupyter_data_dir

d = jupyter_data_dir()
if not os.path.exists(d):
    os.makedirs(d)
"""

    pip install https://github.com/ipython-contrib/IPython-notebook-extensions/archive/master.zip
}

autostart_jupyter()
{
    sudo tee /etc/systemd/system/jupyter-notebook.service > /dev/null <<EOF
[Unit]
Description=Jupyter notebook
Wants=network-online.target
After=network.target network-online.target

[Service]
PIDFile=/var/run/jupyter-notebook.pid
Environment="PATH=$PATH"
ExecStart=$HOME/miniconda/bin/jupyter notebook
User=poppy
Group=poppy
WorkingDirectory=$JUPTER_NOTEBOOK_FOLDER
Type=simple

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable jupyter-notebook.service
}

install_conda
install_python_packages
configure_jupyter
autostart_jupyter
