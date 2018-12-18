#!/usr/bin/env bash

# Disable SELinux
setenforce 0

cd /tmp

# VirtualBox guest additions
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y wget gcc kernel-devel

LATEST_STABLE_VB=$(curl http://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)
wget -q http://download.virtualbox.org/virtualbox/${LATEST_STABLE_VB}/VBoxGuestAdditions_${LATEST_STABLE_VB}.iso
mkdir /media/VBoxGuestAdditions
mount -o loop,ro VBoxGuestAdditions_${LATEST_STABLE_VB}.iso /media/VBoxGuestAdditions
sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
umount /media/VBoxGuestAdditions
rm VBoxGuestAdditions_${LATEST_STABLE_VB}.iso
rmdir /media/VBoxGuestAdditions

# PHP and Apache
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum --enablerepo=remi,remi-php72 install -y httpd php php-common php-pgsql

# Create web root
rmdir /var/www/cgi-bin
rmdir /var/www/html
mkdir /var/www/public
chown -R apache /var/www

# Give log ownership to vagrant
chown -R vagrant /var/log/httpd

# Set ServerName
sed -i 's,#ServerName www.example.com:80,ServerName cappuccino:80,g' /etc/httpd/conf/httpd.conf
# Unset DocumentRoot
sed -i 's,DocumentRoot "/var/www/html",#DocumentRoot "/var/www/html",g' /etc/httpd/conf/httpd.conf

rm /etc/httpd/conf.d/README
rm /etc/httpd/conf.d/welcome.conf

# Configure VirtualHost
WEB_CONFIG='<VirtualHost *:80>
  ServerName cappuccino
  ServerAdmin webmaster@localhost
  DocumentRoot /var/www/public

  <Directory /var/www/public>
    AllowOverride All
    Order Allow,Deny
    Allow from All
    Options FollowSymlinks
  </Directory>

  ErrorLog /var/log/httpd/error.log
  CustomLog /var/log/httpd/access.log combined
</VirtualHost>'

echo "${WEB_CONFIG}" > /etc/httpd/conf.d/000-default.conf
systemctl enable httpd.service
systemctl start httpd.service

# Composer
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if ["$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE"]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
rm composer-setup.php
chown vagrant:vagrant composer
mv composer.phar /usr/local/bin

# PostgreSQL
rpm -Uvh https://yum.postgresql.org/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm
yum install -y postgresql10-server

/usr/pgsql-10/bin/postgresql-10-setup initdb

systemctl start postgresql-10.service
systemctl enable postgresql-10.service

sudo -u postgres createuser vagrant --superuser
sudo -u vagrant createdb cappuccino

cat /dev/null > ~/.bash_history && history -c
