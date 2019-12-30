#!/bin/bash

### This is for the User VS-Code Machines and will be run from Cloud-Init 

# Set Editor System wide - for easyness to "new" Linux Users we want nano to be the Editor
git config --global credential.helper store
git config --global core.editor "nano"
export GIT_EDITOR=nano
export EDITOR=nano
export VISUAL=nano

# Set Root Pass
echo "root:${password}" | chpasswd

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install docker compose
curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Setup the Hostname for Traefik-label
cd /srv/vscode
echo HOSTNAME=$HOSTNAME > .env

# Dirty but worky
# Start up dem Containers of VS-Code.
docker-compose up -d