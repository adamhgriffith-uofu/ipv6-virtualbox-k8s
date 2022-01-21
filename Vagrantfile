# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 2.0.0"

# Load Ruby Gems:
require 'yaml'

# Environmental Variables:
ENV['BRIDGED_ADAPTER'] = "enp8s0"
ENV['KUBE_VERSION'] = "1.23.*"
ENV['METALLB_VERSION'] = "0.11.0"

# Load servers from file:
servers = YAML.load_file('./servers.yml')

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Avoid updating the guest additions if the user has the plugin installed:
#   if Vagrant.has_plugin?("vagrant-vbguest")
#     config.vbguest.auto_update = false
#   end

  # Necessary for mounts (see https://www.puppeteers.net/blog/fixing-vagrant-vbguest-for-the-centos-7-base-box/).
  config.vbguest.installer_options = { allow_kernel_upgrade: true }

  # Display a note when running the machine.
  config.vm.post_up_message = "Remember, switch to root shell before running K8s commands!"

  # Share an additional folder to the guest VM.
  config.vm.synced_folder "./work", "/vagrant_work", SharedFoldersEnableSymlinksCreate: false

  ##############################################################
  # Create the nodes.                                          #
  ##############################################################
  servers.each_with_index do |server, index|

    config.vm.define server['name'] do |node|

      node.vm.box = "centos/7"
      node.vm.hostname = server['name']

      # Create a bridged network adaptor (for IPv6).
      node.vm.network "public_network", auto_config: false, bridge: ENV['BRIDGED_ADAPTER']

      # VirtualBox Provider
      node.vm.provider "virtualbox" do |vb|
        # Customize the number of CPUs on the VM:
        vb.cpus = 2

        # Customize the network drivers:
        vb.default_nic_type = "virtio"

        # Display the VirtualBox GUI when booting the machine:
        vb.gui = false

        # Customize the amount of memory on the VM:
        vb.memory = 4096

        # Customize the name that appears in the VirtualBox GUI:
        vb.name = server['name']
      end

      if index < 1
        # Perform housekeeping on `vagrant destroy` of the control-plane (a.k.a. master) node..
        node.trigger.before :destroy do |trigger|
          trigger.warn = "Performing housekeeping before starting destroy..."
          trigger.run_remote = {path: "./scripts/cluster/housekeeping.sh"}
        end
      end

      # Provision with shell scripts.
      node.vm.provision "shell" do |script|
        script.env = {
            SEARCH_DOMAINS: server['search_domains'],
            IPV6_ADDR: server['ipv6'],
            IPV6_GW: server['ipv6_gw']
        }
        script.path = "./scripts/os-requirements.sh"
      end
      node.vm.provision "shell", path: "./scripts/cluster/docker.sh"
      node.vm.provision "shell" do |script|
        script.env = {
          KUBE_VERSION:ENV['KUBE_VERSION']
        }
        script.path = "./scripts/cluster/kubernetes.sh"
      end
      if index < 1
        # The control-plane (a.k.a. master) node.
        node.vm.provision "shell" do |script|
          script.env = {
            IPV6_ADDR: server['ipv6'],
            METALLB_VERSION:ENV['METALLB_VERSION']
          }
          script.path = "./scripts/cluster/master.sh"
        end
      else
        # The worker nodes.
        node.vm.provision "shell", path: "./scripts/cluster/worker.sh"
      end
    end
  end
end
