#!/bin/bash
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

# Update the package index and install required packages
apt update
apt install -y python3-pip python3-dev build-essential libpcre3 libpcre3-dev libssl-dev uwsgi

# Upgrade pip
pip3 install --upgrade pip

# Download the application code
curl -L https://github.com/$ORG_NAME/$REPO_NAME/tarball/$REPO_BRANCH > $REPO_NAME.tar.gz

# Create a new user and group to run the application
groupadd -f $USER_NAME
useradd -g $USER_NAME --no-create-home --shell /bin/false $USER_NAME

# Create a directory for the application configuration files
mkdir /etc/$SERVICE_NAME
chown $USER_NAME:$USER_NAME /etc/$SERVICE_NAME

# Extract the application code and install dependencies
mkdir -p $SERVICE_NAME
tar -xzf $REPO_NAME.tar.gz -C $SERVICE_NAME --strip-components=1
pip3 install -r ./$SERVICE_NAME/requirements.txt

# Move the application code to /opt and change ownership
mv $SERVICE_NAME /opt
chown -R $USER_NAME:$USER_NAME /opt/$SERVICE_NAME

# Create a directory for uWSGI vassals and a configuration file for the emperor
mkdir -p /etc/uwsgi/vassals
cat > /etc/uwsgi/emperor.ini <<EOL
[uwsgi]
emperor = /etc/uwsgi/vassals
EOL
chown -R $USER_NAME:$USER_NAME /etc/uwsgi

# Create a vassal configuration file for the application
cat > /etc/uwsgi/vassals/$CLUSTER.ini <<EOL
[uwsgi]
http = :$PORT
pidfile = /tmp/$KEY.pid
env = CB_DATABASE=$KEY
processes = 1
master =
chdir = /opt/$SERVICE_NAME/src
wsgi-file = /opt/$SERVICE_NAME/src/wsgi.py
enable-threads =
EOL
chown $USER_NAME:$USER_NAME /etc/uwsgi/vassals/$CLUSTER.ini

# Create a systemd service for the emperor
cat > /etc/systemd/system/emperor.uwsgi.service <<EOL
[Unit]
Description=uWSGI Emperor
After=syslog.target

[Service]
User=$USER_NAME
Group=$USER_NAME
ExecStart=/usr/bin/uwsgi --ini /etc/uwsgi/emperor.ini
RuntimeDirectory=/opt/$SERVICE_NAME
Restart=always
KillSignal=SIGQUIT
Type=notify
StandardError=syslog
NotifyAccess=all

[Install]
WantedBy=multi-user.target
EOL

# Change ownership of the service file
chown $USER_NAME:$USER_NAME /etc/systemd/system/emperor.uwsgi.service

# Reload systemd and start the emperor service
systemctl daemon-reload
systemctl start emperor.uwsgi.service

# Check the status of the emperor service and enable it to start at boot
systemctl status emperor.uwsgi.service
systemctl enable emperor.uwsgi.service