#!/bin/bash

set -e

program_name=$0

function usage() {
  echo "Poppy robot installation script"
  echo ""
  echo "usage: $program_name"
  echo "   or: $program_name [--argument=argument-value]"
  echo ""
  echo "Arguments:"
  echo "  --creature           Set the robot type (default: poppy-ergo-jr)"
  echo "  --username           Set the Poppy user name (default: poppy)"
  echo "  --password           Set password for the Poppy user (default: poppy)"
  echo "  --hostname           Set the robot hostname (default: poppy)"
  echo "  --shutdown           Shutdown the system after installation"
  echo "  -?|--help            Show this help"
  exit
}

for i in "$@"
do
case $i in
  -?|--help)
  usage
  exit
  shift
  ;;
  --creature=*)
  POPPY_CREATURE="${i#*=}"
  shift
  ;;
  --username=*)
  POPPY_USERNAME="${i#*=}"
  shift
  ;;
  --password=*)
  POPPY_PASSWORD="${i#*=}"
  shift
  ;;
  --hostname=*)
  POPPY_HOSTNAME="${i#*=}"
  shift
  ;;
  -s|--shutdown)
  SHUTDOWN=true
  shift
  ;;
esac
done

POPPY_CREATURE=${POPPY_CREATURE:-"poppy-ergo-jr"}
POPPY_USERNAME=${POPPY_USERNAME:-"poppy"}
POPPY_PASSWORD=${POPPY_PASSWORD:-"poppy"}
POPPY_HOSTNAME=${POPPY_HOSTNAME:-"poppy"}

url_root="https://raw.githubusercontent.com/poppy-project/raspoppy/master"

cd /tmp || exit
wget $url_root/setup-system.sh
bash setup-system.sh "$POPPY_USERNAME" "$POPPY_PASSWORD"

wget $url_root/setup-python.sh
sudo -u $POPPY_USERNAME bash setup-python.sh

wget $url_root/setup-poppy.sh
sudo -u $POPPY_USERNAME bash setup-poppy.sh "$POPPY_CREATURE" "$POPPY_HOSTNAME"

echo -e "\e[33mChange hostname to \e[4m$POPPY_HOSTNAME.\e[0m"
sudo raspi-config --change-hostname "$POPPY_HOSTNAME"

if [ "$SHUTDOWN" = true ]; then
  sudo shutdown -h now
fi
