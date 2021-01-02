#!/usr/bin/env bash

set -euo pipefail

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

echo "Installing prerequisites..."
apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - 

echo "Adding Docker APT registry..."
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" 

echo "Updaing APT..."
apt-get -y update 

echo "Installing docker..."
apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose 

echo "Adding ubuntu to docker group..."
usermod -aG docker ubuntu 

echo "Updating all packages..."
apt-get -y upgrade 

echo "Setting hostname..."
hostnamectl set-hostname draftcab.io 

echo "Please reboot."
