☕ Cappuccino
=============
A simple Vagrant development box. Nothing to do with coffee.

Includes
--------
* CentOS 7
* Apache 2.4
* PostgreSQL 10.6
* PHP 7.2
* U
* Composer
* C
* I
* N
* O

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

This assumes your web root is `public/`. Add this line to swap to `web/` or something else.

Database
--------
By default, there's a database called `cappuccino`. The vagrant user is a superuser so you can
simply run `psql` after connecting to the virtual machine with `vagrant ssh`.
