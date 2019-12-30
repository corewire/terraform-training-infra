#!/bin/bash

### This File is for the "Main" Server with Gitlab and some Api things etc.

# Set Root Pass
echo "root:${password}" | chpasswd

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
