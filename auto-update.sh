#!/usr/bin/env bash

echo -e "Starting update on $(date)."

# WARNING puppet-master (web interface) is needed to have the installed creature
creature=`grep "creature" $HOME/.poppy_config.yaml | awk -F ": " '{print $2}'`
pip install --upgrade "$creature"
pip install --upgrade pypot

echo -e "Done."
