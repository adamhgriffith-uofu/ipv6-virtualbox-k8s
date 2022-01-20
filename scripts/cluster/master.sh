#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Configure Kubernetes Master Node                                                ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "Initializing the Kubernetes cluster with Kubeadm.."
kubeadm config images pull
cat << EOF > /tmp/kubeadm-config.yml
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${IPV6_ADDR}
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: node0001
  kubeletExtraArgs:
    cluster-dns: fc00:db8:1234:5678:8:3:0:a
    node-ip: ${IPV6_ADDR}
---
apiServer:
  extraArgs:
    advertise-address: ${IPV6_ADDR}
    bind-address: '::'
    etcd-servers: https://[${IPV6_ADDR}]:2379
    service-cluster-ip-range: fc00:db8:1234:5678:8:3::/112
apiVersion: kubeadm.k8s.io/v1beta2
controllerManager:
  extraArgs:
    allocate-node-cidrs: 'true'
    bind-address: '::'
    cluster-cidr: fc00:db8:1234:5678:8:2::/104
    node-cidr-mask-size: '120'
    service-cluster-ip-range: fc00:db8:1234:5678:8:3::/112
etcd:
  local:
    dataDir: /var/lib/etcd
    extraArgs:
      advertise-client-urls: https://[${IPV6_ADDR}]:2379
      initial-advertise-peer-urls: https://[${IPV6_ADDR}]:2380
      initial-cluster: ${HOSTNAME}=https://[${IPV6_ADDR}]:2380
      listen-client-urls: https://[${IPV6_ADDR}]:2379
      listen-peer-urls: https://[${IPV6_ADDR}]:2380
kind: ClusterConfiguration
networking:
  serviceSubnet: fc00:db8:1234:5678:8:3::/112
scheduler:
  extraArgs:
    bind-address: '::'
---
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
clusterDNS:
- fc00:db8:1234:5678:8:3:0:a
healthzBindAddress: ::1
kind: KubeletConfiguration
EOF
kubeadm init --config=/tmp/kubeadm-config.yml

echo "Enabling kubectl access for root..."
mkdir -p "$HOME/.kube"
cp -i "/etc/kubernetes/admin.conf" "$HOME/.kube/config"
chown $(id -u):$(id -g) "$HOME/.kube/config"

echo "Creating Pod network via Calico..."
kubectl apply -f /vagrant/resources/manifests/calico.yml
#kubectl apply -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
#kubectl apply -f https://docs.projectcalico.org/manifests/custom-resources.yaml

echo "Creating new cluster join script..."
touch /vagrant_work/join.sh
chmod +x /vagrant_work/join.sh
kubeadm token create --print-join-command > /vagrant_work/join.sh

#echo "Creating load-balancing via MetalLB..."
#kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v${METALLB_VERSION}/manifests/namespace.yaml
#kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v${METALLB_VERSION}/manifests/metallb.yaml
#cat <<EOF > /tmp/metallb-config.yaml
#apiVersion: v1
#kind: ConfigMap
#metadata:
#  namespace: metallb-system
#  name: config
#data:
#  config: |
#    address-pools:
#    - name: default
#      protocol: layer2
#      addresses:
#      - 192.168.56.11-192.168.56.12
#EOF
#kubectl apply -f /tmp/metallb-config.yaml

# TODO: Put the master node taint back. This is temporary while debugging.
echo "Temporarily removing master taint for debugging..."
kubectl taint nodes --all node-role.kubernetes.io/master-