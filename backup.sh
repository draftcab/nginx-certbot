#!/usr/bin/env bash

set -euo pipefail

BUCKET_PATH="s3://dc-backups-sdihuf"

echo "Checking permissions..."
# Check if user is root. We need to be ubuntu as that's where the AWS credentials are stored. Root won't have permission (strange, I know)
if [ "$EUID" -eq 0 ]
then echo "Please run as ubuntu (don't use sudo)"
  exit
fi

# Make sure we CAN sudo, because we need to in order to make some of the archives, but we can't run the S3 commands as root
# In the backup steps, we can run tar with sudo, and the piped command will run as ubuntu
if ! [ -x "$(command -v sudo -v)" ]; then
  echo 'Error: User ${USER} is not in the sudoers file and needs to be.' >&2
  exit 1
fi

echo "Checking AWS credentials..."
# Run an 'ls' on the S3 bucket. If this succeeds, then we should have the permissions needed to run the backup
aws s3 ls ${BUCKET_PATH} 2>&1 > /dev/null

if [ "$?" -ne 0 ]; then
  echo 'Error: unable to reach S3 bucket. Did you set up the aws credentials?' >&2
  exit 1
fi

# Check if postgres is running. Backing up and restoring while it's live may be a bad idea
echo "Checking if Postgres is running..."
POSTGRES_NAME='.*postgres.*'
status=$(docker ps -qf "name=${POSTGRES_NAME}" --format='{{.Status}}')
if [[ -n $status ]]; then
  echo "Error: Postgres appears to be running. It's not safe to backup or restore until it's stopped." >&2
  exit 1
fi

# the P flag allows for absolute file names. We want the full path in the archive
echo "Backing up /etc/ssh"
sudo tar czfP - /etc/ssh | aws s3 cp - s3://dc-backups-sdihuf/ssh.tar.gz

echo "Backing up draftcab data"
sudo tar czfP - ~/draftcab/docker | aws s3 cp - s3://dc-backups-sdihuf/backup.tar.gz

echo "Backing up secrets"
tar czfP - ~/.ssh ~/secrets.env | aws s3 cp - s3://dc-backups-sdihuf/secrets.tar.gz