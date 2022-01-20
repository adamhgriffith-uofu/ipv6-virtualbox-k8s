#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Install and configure Docker                                                    ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "Adding the yum-config-manager tool..."
yum install yum-utils -y

echo "Adding the stable Docker repo to yum..."
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "Installing the latest version of DockerCE and containerd..."
yum install docker-ce docker-ce-cli containerd.io -y

# Following configurations are recommended in the kubernetes documentation for Docker runtime. Please refer
# to https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker
mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

echo "Enabling Docker through systemctl..."
systemctl enable --now docker