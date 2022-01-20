# VirtualBox and IPv6 Kubernetes

Tools to create IPv6 K8s with VirtualBox.

## Requirements

### VirtualBox

See [Virtual Box](https://www.virtualbox.org/) for download and installation instructions.

### Vagrant

* [Download vagrant](https://www.vagrantup.com/downloads) and follow the installer's instructions.
* Install the Virtualbox Guest Additions via the following command:

  ```shell
  vagrant plugin install vagrant-vbguest
  ```

  **Note:** you will receive the mount errors described in [Vagrant No VirtualBox Guest Additions installation found](https://www.devopsroles.com/vagrant-no-virtualbox-guest-additions-installation-found-fixed/).
* Enable autocompletion:

  ```shell
  vagrant autocomplete install --bash
  ```
  
## Build and Run

1. Update the name of the bridged adaptor in the `Vagrantfile` to match the host.
2. Copy `/<repo-location>/servers.yml.tmpl` to `/<repo-location>/servers.yml` and modify as needed.
   * The first entry will be applied to the control-plane and the remainder to the worker nodes.
   * **Note:** If a single entry is specified only the control-plane will be created.
3. Bring up the virtual machines:

   ```shell
   vagrant up
   ```

### Initialize K8s Cluster

Initialization is done for you.

* The host directory `/<repo-location>/work` is mounted at `/vagrant_work` on each virtual machine.
* When the control-plane is created it will generate `/<repo-location>/work/join.sh`.
* `/<repo-location>/work/join.sh` will be used by the worker nodes to join the Kubernetes cluster automatically.

## Teardown

Tearing down the virtual machines and clearing the old `/<repo-location>/work/join.sh` is done with a single command:

```shell
vagrant destroy -f
```

See [Vagrant: Destroy](https://www.vagrantup.com/docs/cli/destroy) for additional information.

## References
