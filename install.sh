#!/usr/bin/env bash

# Path to this script
SCRIPT=$(readlink -f "$0")
# Folder this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Create all the subfolders unicorn is expecting
mkdir -p $SCRIPTPATH/tmp/pids
mkdir -p $SCRIPTPATH/tmp/sockets
mkdir -p $SCRIPTPATH/log

# And the one our own code expects
mkdir -p $SCRIPTPATH/public/audio

echo "Directory tree created"

# Set our folder in every config file that needs it hardcoded
sed -i "s/INSTALLDIR/$(SCRIPTPATH)/g" nginx_servicedispatch
sed -i "s/INSTALLDIR/$(SCRIPTPATH)/g" unicorn.rb

echo "Configuration files updated"
echo "You should now put 'nginx_servicedispatch' in /etc/nginx/sites_available and link to it in /etc/nginx/sites_enabled to activate the website"
