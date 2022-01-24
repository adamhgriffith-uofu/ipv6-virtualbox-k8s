#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Housekeeping                                                                    ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

if [ -f "/vagrant_work/admin.conf" ]
then
  echo "Deleting old kubeconfig (admin.conf)..."
  rm /vagrant_work/admin.conf
fi

if [ -f "/vagrant_work/join-config.yml.part" ]
then
  echo "Deleting old /vagrant_work/join-config.yml.part..."
  rm /vagrant_work/join-config.yml.part
fi

if [ -f "/vagrant_work/join-config.yml" ]
then
  echo "Deleting old /vagrant_work/join-config.yml..."
  rm /vagrant_work/join-config.yml
fi