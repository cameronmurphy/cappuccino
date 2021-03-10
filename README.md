☕ Cappuccino
=============
A simple lightweight VirtualBox Vagrant development box. Nothing to do with coffee. Designed primarily for Symfony, Laravel and Craft CMS development.

Acrostic poem
-------------
* **C**entOS 8
* **A**pache 2.4
* **P**ostgreSQL 13.2
* **P**HP 8, PHP-FPM
* **U**nder 1GB
* **C**omposer 2
* **C**LI tools (wget, unzip, git, vim)
* **I** like ice cream 🍦
* **N**VM, Node.js, npm, Yarn
* **O**h, also MariaDB 10.3

Building
--------
```bash
$ vagrant up
$ vagrant package --output cappuccino.box
```
This box is already available in [Vagrant Cloud](https://app.vagrantup.com/camurphy/boxes/cappuccino) so you won't need to build it yourself.

Usage
-----
Basic Vagrantfile example:
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "camurphy/cappuccino"
  config.vm.network "private_network", type: "dhcp"
  config.vm.synced_folder ".", "/var/www", type: "nfs"
end
```

This assumes your web root is `public/`. Add this within the configure block to use `web/` or something else.
```ruby
  config.vm.provision "shell", inline: <<-'SHELL'
    sed -i "s,/var/www/public,/var/www/web,g" /etc/httpd/conf.d/000-default.conf
    systemctl restart httpd.service
  SHELL
```

If you need additional PHP extensions installed, below is an example of how you'd install php-soap. Add this within the
configure block.
```ruby
  config.vm.provision "shell", inline: <<-'SHELL'
    dnf install -y php-soap
    systemctl restart php-fpm.service
  SHELL
```

Databases
---------
Postgres
```
Host: 127.0.0.1
Port: 5432
Name: cappuccino
User: vagrant
Pass: vagrant
```
MySQL (MariaDB)
```
Host: 127.0.0.1
Port: 3306
Name: cappuccino
User: vagrant
Pass: vagrant
```
There's also a database called `cappuccino_test` in each to run your test suite against.

Advanced usage
--------------
I like my Vagrant machines to have a convenient hostname, i.e. [cappuccino.wip](http://cappuccino.wip). I use the
[vagrant-hostsmanager](https://github.com/devopsgroup-io/vagrant-hostmanager) plugin to automatically update my host
machine's `hosts` file.
```ruby
Vagrant.require_version ">= 2.1.4"

Vagrant.configure("2") do |config|
  config.vagrant.plugins = ["vagrant-hostmanager"]

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ip_resolver = proc do |vm|
    if vm.id
      `VBoxManage guestproperty get #{vm.id} "/VirtualBox/GuestInfo/Net/1/V4/IP"`.split[1]
    end
  end

  config.vm.box = "camurphy/cappuccino"
  config.vm.network "private_network", type: "dhcp"
  config.vm.hostname = "cappuccino.wip"
  config.vm.synced_folder ".", "/var/www", type: "nfs"
end
```
When your VM boots, your `hosts` file will be updated to include a block similar to below:
```bash
## vagrant-hostmanager-start id: b9cd2b8d-6266-4cdf-b5f1-7ca7289a1b91
172.28.128.3   cappuccino.wip
## vagrant-hostmanager-end
```
The net result being, immediately after running `vagrant up`, your application is accessible at http://cappuccino.wip :)
The above is automatically removed from your hosts file when the Vagrant machine is destroyed.
