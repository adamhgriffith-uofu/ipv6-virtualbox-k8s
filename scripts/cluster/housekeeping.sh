#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Housekeeping                                                                    ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

if [ -f "/vagrant_work/join-config.yml.part" ]
then
  echo "Deleting old /vagrant_work/join-config.yml.part..."
  rm /vagrant_work/join-config.yml.part
fi