# power on:  vagrant up --provider=virtualbox --color
# power off: vagrant halt -f
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.box_version = "2004.01"
  config.vm.box_check_update = false
  #config.vm.provision "shell", privileged: false, path: "./setup.sh"

  config.ssh.insert_key = false

  config.vm.provider "virtualbox" do |v|
    v.linked_clone = true
    v.memory = 2048
    v.cpus = 2
    #v.gui = true
  end

  config.vm.define "k8s-master" do |v|
    v.vm.hostname = "k8s-master"
    v.vm.network "private_network", ip: "172.16.80.20"
  end

  config.vm.define "k8s-node01" do |v|
    v.vm.hostname = "k8s-node01"
    v.vm.network "private_network", ip: "172.16.80.21"
  end

  config.vm.define "k8s-node02" do |v|
    v.vm.hostname = "k8s-node02"
    v.vm.network "private_network", ip: "172.16.80.22"
  end
end
