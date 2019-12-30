#!/bin/bash

# This File is run by Cloud-init for the "Linux-only" machines.

# Set Editor System wide - for easy use it is nano
git config --global core.editor "nano"
export GIT_EDITOR=nano
export EDITOR=nano
export VISUAL=nano

# Set root Login
echo "root:${password}" | chpasswd

# update system and install some dependencies
apt-get update && apt-get upgrade -y && apt-get install tree -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install docker compose
curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose