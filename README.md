☕ Cappuccino
=============
A simple lightweight Vagrant development box. Nothing to do with coffee. Designed primarily for Symfony and Craft CMS
development.

Includes
--------
* CentOS 7
* Apache 2.4
* PostgreSQL 10.6
* PHP 7.2
* U
* Composer
* CLI tools (wget, unzip, git, vim)
* I
* NVM, node, npm
* Oh yeah!

Building
--------
```bash
$ vagrant up
$ vagrant package --output cappuccino.box
```

Usage
-----
Basic Vagrantfile example:
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "cappuccino"
  config.vm.network "private_network", type: "dhcp"
  config.vm.synced_folder ".", "/var/www", :mount_options => ["dmode=777", "fmode=777"]
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
    yum --enablerepo=remi,remi-php72 install -y php-soap
    systemctl restart httpd.service
  SHELL
```

Database
--------
```
Host: 127.0.0.1
Port: 5432
Name: cappuccino
User: vagrant
Pass: vagrant
```

Advanced usage
--------------
I like my Vagrant machines to have a convenient hostname, i.e. [cappuccino.wip](http://cappuccino.wip). I also use
`dotenv` for my projects so below is an example of using the [vagrant-env](https://github.com/gosuri/vagrant-env) plugin
to read a `HOSTNAME` variable from your `.env` file. This value gets passed to the 
[vagrant-hostsmanager](https://github.com/devopsgroup-io/vagrant-hostmanager) plugin to automatically update your host
machine's `hosts` file.
```ruby
Vagrant.require_version ">= 2.1.4"

Vagrant.configure("2") do |config|
  config.vagrant.plugins = ["vagrant-env", "vagrant-hostmanager"]

  config.env.enable
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
    if vm.id
      `VBoxManage guestproperty get #{vm.id} "/VirtualBox/GuestInfo/Net/1/V4/IP"`.split()[1]
    end
  end

  config.vm.box = "cappuccino"
  config.vm.network "private_network", type: "dhcp"
  config.vm.hostname = ENV["HOSTNAME"]
  config.vm.synced_folder ".", "/var/www", :mount_options => ["dmode=777", "fmode=777"]

  # Wait long enough to get an IP from DHCP server
  config.vm.provision "shell", run: "always", inline: "sleep 8"
end
```
Provided your .env file contained `HOSTNAME=cappuccino.wip`, your `hosts` file will be updated to include a block
similar to below:
```bash
## vagrant-hostmanager-start id: b9cd2b8d-6266-4cdf-b5f1-7ca7289a1b91
172.28.128.3	cappuccino.wip
## vagrant-hostmanager-end
```
The net result being, immediately after running `vagrant up`, your application is accessible at http://cappuccino.wip :)
The above is automatically removed from your hosts file when the Vagrant machine is destroyed.