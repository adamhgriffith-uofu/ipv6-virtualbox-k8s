#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Configure Kubernetes Control Plane                                              ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "Initializing the Kubernetes cluster with Kubeadm.."
kubeadm config images pull
cat << EOF > /tmp/kubeadm-config.yml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${IPV6_ADDR}
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: ${HOSTNAME}
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
apiVersion: kubeadm.k8s.io/v1beta3
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
cat <<EOF > /tmp/calico-config.yml
# Source: calico/templates/calico-config.yaml
# This ConfigMap is used to configure a self-hosted Calico installation.
kind: ConfigMap
apiVersion: v1
metadata:
  name: calico-config
  namespace: kube-system
data:
  # Typha is disabled.
  typha_service_name: "none"
  # Configure the backend to use.
  calico_backend: "bird"

  # Configure the MTU to use for workload interfaces and tunnels.
  # By default, MTU is auto-detected, and explicitly setting this field should not be required.
  # You can override auto-detection by providing a non-zero value.
  veth_mtu: "0"

  # The CNI network configuration to install on each node. The special
  # values in this config will be automatically populated.
  cni_network_config: |-
    {
      "name": "k8s-pod-network",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "calico",
          "log_level": "info",
          "log_file_path": "/var/log/calico/cni/cni.log",
          "datastore_type": "kubernetes",
          "nodename": "${HOSTNAME}",
          "mtu": 1500,
          "ipam": {
              "type": "calico-ipam",
              "assign_ipv4": "false",
              "assign_ipv6": "true"
          },
          "policy": {
              "type": "k8s"
          },
          "kubernetes": {
              "kubeconfig": "/etc/kubernetes/admin.conf"
          }
        },
        {
          "type": "portmap",
          "snat": true,
          "capabilities": {"portMappings": true}
        },
        {
          "type": "bandwidth",
          "capabilities": {"bandwidth": true}
        }
      ]
    }
EOF
kubectl apply -f /tmp/calico-config.yml
kubectl apply -f /vagrant/resources/manifests/calico.yml
#kubectl apply -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
#kubectl apply -f https://docs.projectcalico.org/manifests/custom-resources.yaml

echo "Installing calicoctl..."
kubectl apply -f /vagrant/resources/manifests/calicoctl.yaml
cat <<EOF >> $HOME/.bashrc
alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"
EOF

echo "Creating portion of new cluster join config..."
K8_TOKEN=$(kubeadm token create)
K8_DISCO_CERT=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
cat <<EOF > /vagrant_work/join-config.yml.part
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: "[${IPV6_ADDR}]:6443"
    token: "${K8_TOKEN}"
    caCertHashes:
    - "sha256:${K8_DISCO_CERT}"
EOF

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