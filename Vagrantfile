# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vagrant.plugins = ["vagrant-reload"]

  config.vm.box = "centos/8"

  config.vm.provision "shell", inline: "dnf -y update && dnf -y upgrade", keep_color: true
  # Reboot in case kernel was upgraded
  config.vm.provision :reload
  config.vm.provision "shell", path: "build-privileged.sh", keep_color: true
  config.vm.provision "shell", path: "build-vagrant-usr.sh", privileged: false, keep_color: true
end
