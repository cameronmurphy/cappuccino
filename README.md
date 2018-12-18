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
* No bloat.
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

If you need additional PHP extensions install add this within the configure block.
```ruby
  config.vm.provision "shell", inline: <<-'SHELL'
    yum --enablerepo=remi,remi-php72 install -y php-soap
    systemctl restart httpd.service
  SHELL
```

Database
--------
By default, there's a database called `cappuccino`. The vagrant user is a superuser so you can
simply run `psql` to connect with ident authentication.
