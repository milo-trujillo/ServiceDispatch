#!/usr/bin/env bash

# Folder this script is in
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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

if command -v bundle > /dev/null; then
	bundle install
	echo "Ruby dependencies installed"
else
	echo "Please install ruby dependencies in the gem file"
fi

echo "You should now put 'nginx_servicedispatch' in /etc/nginx/sites_available and link to it in /etc/nginx/sites_enabled to activate the website"
