#!/usr/bin/env bash

url=$1
logs=$2
lockfile=$3

now=$(date +"%Y-%m-%d-%H-%M-%S")

echo "$$" > $lockfile

echo "Downloading update file form $url..."
wget $url -O auto-update.sh
if [ $? -ne 0 ]; then
    echo "Could not download file from $url."
    echo "Check that your robot is connected to internet and try again."
    exit 1
fi

bash auto-update.sh > $logs 2>&1
if [ $? -ne 0 ]; then
    echo "Update failed!"
else
    echo "Update successful!"
fi
echo "Please check $logs for details."

cp $logs "$logs.$now.bkp"
rm $lockfile
