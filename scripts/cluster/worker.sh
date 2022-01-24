#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Configure Kubernetes Worker Node                                                ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "Joining the cluster as a worker..."
JOIN_CONFIG_PATH=/vagrant_work/join-config.yml
cp /vagrant_work/join-config.yml.part "${JOIN_CONFIG_PATH}"
cat <<EOF >> "${JOIN_CONFIG_PATH}"
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: ${HOSTNAME}
  kubeletExtraArgs:
    node-ip: ${IPV6_ADDR}
EOF
kubeadm join --config="${JOIN_CONFIG_PATH}"