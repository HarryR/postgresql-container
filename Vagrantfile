# -*- mode: ruby -*-
# vi: set ft=ruby :


unless Vagrant.has_plugin?("vagrant-persistent-storage")
  raise 'vagrant-persistent-storage is not installed!'
end

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu-16.04-lts-i386"
  config.vm.box_url = "https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-i386-vagrant.box"

  config.vm.host_name = "postgresql" 
  config.vm.network "forwarded_port", guest: 5432, host: 5432

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "data/conf", "/opt/psql-conf", mount_options: ["dmode=700,fmode=600"], owner: 0, group: 0, create: true

  config.vm.provision "shell", path: "provision/01-cleanservices.sh"
  config.vm.provision "shell", path: "provision/02-apt.sh"
  config.vm.provision "shell", path: "provision/03-ufw.sh"
  config.vm.provision "shell", path: "provision/04-persistent.sh"
  config.vm.provision "shell", path: "provision/05-psql.sh"

  config.persistent_storage.enabled = true
  config.persistent_storage.location = File.realpath(".").to_s + "/data/psql.vdi"
  config.persistent_storage.size = 10000
  config.persistent_storage.mountname = 'pgdata'
  config.persistent_storage.filesystem = 'ext4'
  config.persistent_storage.mountpoint = '/var/lib/postgresql'
  config.persistent_storage.volgroupname = 'pgvg'
  config.persistent_storage.mountoptions = ['defaults', 'noatime', 'data=writeback']
  config.persistent_storage.diskdevice = '/dev/sdc'

  config.vm.provider "virtualbox" do |v| 
    v.linked_clone = true
    v.memory = 512 
    v.cpus = 1 
  end 
end
