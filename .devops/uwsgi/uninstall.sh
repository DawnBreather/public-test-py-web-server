#!/bin/bash

# Set environment variables
export KEY="some.couchbase-db"
export PORT="8000"
export ORG_NAME="DawnBreather"
export REPO_NAME="public-test-py-web-server"
export REPO_BRANCH="main"
export SERVICE_NAME="some_service"
export USER_NAME="some_user"
export CLUSTER="$KEY"

# Check if the script is being run as root
if [[ $(id -u) -ne 0 ]]; then
  echo "Please run as root"
  exit 1
fi

# Stop the uWSGI service
systemctl stop emperor.uwsgi.service

# Disable the uWSGI service from starting at boot
systemctl disable emperor.uwsgi.service

# Remove the uWSGI service file
rm /etc/systemd/system/emperor.uwsgi.service

# Remove the uWSGI vassal configuration file
rm /etc/uwsgi/vassals/$CLUSTER.ini

# Remove the uWSGI configuration file
rm /etc/uwsgi/emperor.ini

# Remove the application dependencies
pip3 uninstall -r /opt/$SERVICE_NAME/requirements.txt -y

# Remove the application code directory
rm -rf /opt/$SERVICE_NAME

# Remove the application configuration directory
rm -rf /etc/$SERVICE_NAME

# Remove the application user
userdel -r $USER_NAME

# Remove the application user group
groupdel $USER_NAME