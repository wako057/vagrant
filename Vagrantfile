# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|

  VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))
  fsfilewww = File.join(VAGRANT_ROOT, 'fsfilewww.vdi')
  config.vm.provider "virtualbox" do |v|
	v.gui = true
    v.name = "dev.wako057.net"
    v.memory = 2048
    v.cpus = 2

    unless File.exist?(fsfilewww)
        v.customize ['createhd', '--filename', fsfilewww, '--size', 100 * 1024]
    end 
    v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', fsfilewww]

  end
  
  config.vm.hostname = "dev.wako057.net"
  config.vm.box = "debian/jessie64"
  config.vm.box_version = "8.6.1"
  
  config.vm.provision :shell, path: "bootstrap.sh"

  config.vm.network "private_network", ip: "10.0.0.42"
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  
  
  config.vm.post_up_message = "La vm est prete"
end