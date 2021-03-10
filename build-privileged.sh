#!/usr/bin/env bash

cd /tmp

# Disable SELinux
sed -i 's,SELINUX=enforcing,SELINUX=disabled,g' /etc/selinux/config

# CLI tools
dnf install -y wget unzip git vim tar

# VirtualBox guest additions requirements
dnf install -y kernel-devel perl gcc elfutils-libelf-devel

LATEST_STABLE_VB=$(curl http://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)
wget -q http://download.virtualbox.org/virtualbox/${LATEST_STABLE_VB}/VBoxGuestAdditions_${LATEST_STABLE_VB}.iso
mkdir /media/VBoxGuestAdditions
mount -o loop,ro VBoxGuestAdditions_${LATEST_STABLE_VB}.iso /media/VBoxGuestAdditions
sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
umount /media/VBoxGuestAdditions
rm VBoxGuestAdditions_${LATEST_STABLE_VB}.iso
rmdir /media/VBoxGuestAdditions

# Clean up packages required for VirtualBox guest additions build
dnf remove -y kernel-devel perl gcc elfutils-libelf-devel

## EPEL and Remi's repo
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm

# PHP and Apache
dnf module -y enable php:remi-8.0
dnf install -y httpd php php-pgsql

# PHP extensions required by all
dnf install -y php-zip

# Symfony, Laravel PHP extensions
dnf install -y php-posix php-mbstring php-opcache php-pecl-apcu php-xml

# Craft 3 PHP extensions
dnf install -y php-intl php-imagick php-gd

# Increase PHP memory limit and max execution time to satisfy Craft 3
sed -i 's,memory_limit = [0-9]\+M,memory_limit = 256M,g' /etc/php.ini
sed -i "s,max_execution_time = [[:digit:]]*,max_execution_time = 120,g" /etc/php.ini

# Create web root
rmdir /var/www/cgi-bin
rmdir /var/www/html
mkdir /var/www/public
chown -R apache /var/www

# Give log ownership to apache
chown -R apache /var/log/httpd

# Set ServerName
sed -i 's,#ServerName www.example.com:80,ServerName cappuccino:80,g' /etc/httpd/conf/httpd.conf
# Unset DocumentRoot
sed -i 's,DocumentRoot "/var/www/html",#DocumentRoot "/var/www/html",g' /etc/httpd/conf/httpd.conf

# Remove some redundant files
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

# Composer
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [[ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
rm composer-setup.php
chown vagrant:vagrant composer.phar
mv composer.phar /usr/local/bin/composer

# PostgreSQL
# Disable the built-in PostgreSQL module
dnf module -y disable postgresql
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf install -y postgresql13 postgresql13-server postgresql13-contrib

/usr/pgsql-13/bin/postgresql-13-setup initdb

# Configure Postgres to listen on TCP
sed -i "s,#listen_addresses = 'localhost',listen_addresses = '*'    ,g" /var/lib/pgsql/13/data/postgresql.conf
# Disable ident for local connections
sed -i "s,host    all,#host    all,g" /var/lib/pgsql/13/data/pg_hba.conf
# Enable password authentication for everything
echo 'host    all             all             all                     password' >> /var/lib/pgsql/13/data/pg_hba.conf

systemctl enable postgresql-13.service
systemctl start postgresql-13.service

sudo -u postgres createuser vagrant --superuser
sudo -u postgres psql postgres -c "ALTER USER vagrant WITH PASSWORD 'vagrant';"
sudo -u vagrant createdb cappuccino
sudo -u vagrant createdb cappuccino_test

# MariaDB
dnf install mariadb-server -y
chown -R root:mysql /var/log/mariadb

systemctl enable mariadb.service
systemctl start mariadb.service

mysqladmin -u root password 'vagrant'
mysql -u root -pvagrant -e "CREATE DATABASE cappuccino"
mysql -u root -pvagrant -e "CREATE DATABASE cappuccino_test"
mysql -u root -pvagrant -e "CREATE USER 'vagrant'@'%' IDENTIFIED BY 'vagrant'";
mysql -u root -pvagrant -e "GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%' WITH GRANT OPTION";

# Clear dnf
dnf autoremove -y && dnf clean all

# Clear history
cat /dev/null > ~/.bash_history && history -c
