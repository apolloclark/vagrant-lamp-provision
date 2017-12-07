#!/bin/bash

# set the session to be noninteractive
export DEBIAN_FRONTEND="noninteractive"

# set the dependency versions
APACHE_VERSION="2.4.*"
MYSQL_VERSION="5.7.18"     # needs to be exact
MCAFEE_VERSION="1.1.4-725" # needs to be exact
PHP_VERSION="5.6.*"





## Update the Aptitude cache
apt-get update
apt-get upgrade -y

# install basic services
apt-get install -y software-properties-common wget nano \
	python-software-properties mlocate supervisor build-essential \
	openssh-server iftop nmap git zip unzip debconf-utils

# install system tools
apt-get install -y jq git

# enable colored Bash prompt
cp /vagrant/bash/bashrc /root/.bashrc
cp /vagrant/bash/bashrc /home/vagrant/.bashrc

# enable more robust Nano syntax highlighting
git clone https://github.com/scopatz/nanorc.git /root/.nano
cat /root/.nano/nanorc >> /root/.nanorc
git clone https://github.com/scopatz/nanorc.git /home/vagrant/.nano
cat /home/vagrant/.nano/nanorc >> /home/vagrant/.nanorc

## Disable unneeded services
echo "INFO: Shutting down unused services..."
service rpcbind stop
service puppet stop
service chef-client stop

# enable Ubuntu Firewall and allow SSH & MySQL Ports
ufw enable
ufw allow 22
ufw allow 80
ufw allow 3306
# ufw status verbose

# configure Timezone
echo "America/New_York" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata > /dev/null





## Install Apache
echo "INFO: Install Apache..."
apt-get install -y \
	apache2=$APACHE_VERSION apache2-bin=$APACHE_VERSION apache2-data=$APACHE_VERSION \
	libapache2-mod-security2
update-rc.d apache2 enable

# configure Apache, restart
cp /vagrant/bash/apache/apache2.conf /etc/apache2/apache2.conf
cp /vagrant/bash/apache/15-example.conf /etc/apache2/sites-available/15-example.conf
cp /vagrant/bash/apache/25-security.conf /etc/apache2/conf-available/25-security.conf
a2enmod headers rewrite security2
a2ensite 15-example.conf
a2enconf 25-security.conf
update-rc.d apache2 enable
service apache2 restart 2>&1

# remove old logs, default index, restart
rm -f /var/www/html/logs/*.log
rm /var/www/html/index.html
service apache2 restart

# enable coredumps for Apache
# apt-get install -y --force-yes gdb
# ulimit -c unlimited
# gdb apache2 /tmp/apache2-gdb-dump/coredump-x.x
# (gdb) where





## Install PHP, and plugins
# http://php.net/ChangeLog-5.php
# https://launchpad.net/~ondrej/+archive/ubuntu/php/+index?field.series_filter=xenial
echo "INFO: Install PHP..."

# https://www.digitalocean.com/community/tutorials/how-to-upgrade-to-php-7-on-ubuntu-14-04
# https://secure.php.net/ChangeLog-5.php
apt-get install -y python-software-properties language-pack-en-base software-properties-common
LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php 2>&1
apt-get update

apt-get -qq install -y php5.6 \
	php5.6-cli php5.6-dev php5.6-gd php5.6-json php5.6-mcrypt php5.6-mysql \
	php5.6-xml php5.6-zip libapache2-mod-php5.6 2>&1 > /dev/null
# apt-get -qq install -y --force-yes php-pear
    
# apt-get autoremove -y php7.1*

# configure
echo "INFO: Configuring PHP..."
cp /vagrant/bash/php/php.ini /etc/php/5.6/apache2/php.ini
service apache2 restart





## Install MySQL
echo "INFO: Install MySQL..."

# configure debconf
debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password password toor"
debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password_again password toor"
debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-server select mysql-5.7"
debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-tools select Enabled"
debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-preview select Disable"

# https://dev.mysql.com/doc/relnotes/mysql/5.7/en/
# https://downloads.mysql.com/archives/community/
cd /tmp
wget -q -O mysql-server.tar https://downloads.mysql.com/archives/get/file/mysql-server_$MYSQL_VERSION-1ubuntu16.04_amd64.deb-bundle.tar
tar -xvf mysql-server.tar
apt -qq install -y -f ./mysql-common_*-1ubuntu16.04_amd64.deb 2>&1
apt -qq install -y -f ./libmysqlclient20_*-1ubuntu16.04_amd64.deb 2>&1
apt -qq install -y -f ./mysql-community-client_*-1ubuntu16.04_amd64.deb 2>&1
apt -qq install -y -f ./mysql-client_*-1ubuntu16.04_amd64.deb 2>&1
apt -qq install -y -f ./mysql-community-server_*-1ubuntu16.04_amd64.deb 2>&1
cp /vagrant/bash/mysql/my.cnf /etc/mysql/my.cnf

# configure the root user
mysql -u root -ptoor -e 'USE mysql; CREATE USER `root`@`%`; GRANT ALL PRIVILEGES ON *.* TO `root`@`%` WITH GRANT OPTION; FLUSH PRIVILEGES;'

# install the McAfee mysql-audit plugin
# https://github.com/mcafee/mysql-audit/wiki/Changelog
# https://github.com/mcafee/mysql-audit/wiki/Installation
# https://github.com/mcafee/mysql-audit/releases
# https://bintray.com/mcafee/mysql-audit-plugin/release/
cd /tmp
wget -q -O audit-plugin-mysql.zip https://bintray.com/mcafee/mysql-audit-plugin/download_file?file_path=audit-plugin-mysql-5.7-$MCAFEE_VERSION-linux-x86_64.zip - 
unzip audit-plugin-mysql.zip
mv ./audit-plugin-mysql-5.7-*/lib/libaudit_plugin.so /usr/lib/mysql/plugin/
cp /vagrant/bash/mysql/mcafee-audit.cnf /etc/mysql/conf.d/mcafee-audit.cnf

# rebuild the database, restart
echo "INFO: Setting up the database..."
mysql -u root -ptoor < /vagrant/database.sql
service mysql restart





# setup swap, for PHP Composer
echo "INFO: Setting up Memory Swap..."
/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024 2>&1
/sbin/mkswap /var/swap.1 2>&1
/sbin/swapon /var/swap.1 2>&1

# install PHP dependencies with Composer
echo "INFO: Installing PHP Dependencies..."
cd /var/www/html/public
php composer.phar self-update 2>&1
php composer.phar clear-cache 2>&1
php composer.phar install --no-progress 2>&1





# clear any unneeded dependencies
apt-get -y autoremove

# update the locate file database
updatedb
