#!/usr/bin/env bash

install_conda()
{
    cd || exit
    wget http://repo.continuum.io/miniconda/Miniconda-latest-Linux-armv7l.sh
    bash Miniconda-latest-Linux-armv7l.sh -b
    rm Miniconda-latest-Linux-armv7l.sh

    echo 'export PATH=$HOME/miniconda/bin:$PATH' >> $HOME/.bashrc
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
    JUPTER_NOTEBOOK_FOLDER=$HOME/notebooks

    mkdir $JUPTER_NOTEBOOK_FOLDER

    jupyter notebook --generate-config

    cat >>$JUPYTER_CONFIG_FILE << EOF
# --- Poppy configuration ---
c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '$JUPTER_NOTEBOOK_FOLDER'
# --- Poppy configuration ---
EOF

    python -c """
import os

from jupyter_core.paths import jupyter_data_dir

d = jupyter_data_dir()
if not os.path.exists(d):
    os.makedirs(d)
"""

    pip install https://github.com/ipython-contrib/IPython-notebook-extensions/archive/master.zip --user
}

autostart_jupyter()
{

    cat >> jupyter.service << EOF
[Unit]
Description=Jupyter service

[Service]
Type=simple
ExecStart=$HOME/.jupyter/start-daemon &

[Install]
WantedBy=multi-user.target
EOF

    sudo mv jupyter.service /lib/systemd/system/jupyter.service

    cat >> $HOME/.jupyter/launch.sh << 'EOF'
export PATH=$HOME/miniconda/bin:$PATH
jupyter notebook
EOF

    cat >> $HOME/.jupyter/start-daemon << EOF
#!/bin/bash
su - $(whoami) -c "bash $HOME/.jupyter/launch.sh"
EOF

    chmod +x $HOME/.jupyter/launch.sh $HOME/.jupyter/start-daemon
    sudo systemctl daemon-reload
    sudo systemctl enable jupyter.service
}

install_conda
install_python_packages
configure_jupyter
autostart_jupyter
