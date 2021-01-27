#!/usr/bin/env bash

set -euo pipefail
DRAFTCAB_DATA_PATH="${HOME}/draftcab/modules/draftcab-ui/docker"

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: missing dependencies. Please run init-docker.sh and reboot.' >&2
  exit 1
fi

if ! $(id -nGz "${USER}" | grep -qzxF "docker")
then
  echo "User ${USER} does not belong to the docker group. Please run init-docker.sh or reboot if necessary."
  exit
fi

CERT_PATH="data/certbot/conf/live/draftcab.io"

if [ -d ${CERT_PATH} ] ; then
  echo "Certificate appears valid"
else
  echo "Please run ./init-letsencrypt.sh first and generate a certificate"
  exit
fi


echo "Cloning Draftcab..."
cd ~/
git clone git@github.com:draftcab/platform.git draftcab

echo "Copying SSL certificate and relaxing permissions..."
sudo cp -r ${HOME}/nginx-certbot/data/certbot ${DRAFTCAB_DATA_PATH}
sudo chown -R ${USER} ${DRAFTCAB_DATA_PATH}

echo "Building Draftcab docker image..."
cd ${HOME}/draftcab
docker build . -t draftcab:dev

echo "Starting Draftcab..."
docker-compose up -d

