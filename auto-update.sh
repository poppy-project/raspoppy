#!/usr/bin/env bash

echo -e "Starting update on $(date)."

# Quick fix for creature upgrade
if `python -c "import poppy_ergo_jr"`; then
  conda upgrade poppy-ergo-jr
fi

conda upgrade pypot

echo -e "Done."
