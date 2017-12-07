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


## Deploy

```shell
git clone
cd ./vagrant-lamp/environments/ansible
vagrant up

# http://127.0.0.1:8080

vagrant ssh

mysql -h 127.0.0.1 -u root -p
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