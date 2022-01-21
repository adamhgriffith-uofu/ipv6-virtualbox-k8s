#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Configure Kubernetes Worker Node                                                ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "Joining the cluster as a worker..."
cp /vagrant_work/join-config.yml.part /tmp/join-config.yml
cat <<EOF >> /tmp/join-config.yml
nodeRegistration:
  kubeletExtraArgs:
    node-ip: ${IPV6_ADDR}
EOF
kubeadm join --config=/tmp/join-config.yml