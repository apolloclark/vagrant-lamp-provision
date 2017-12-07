#!/bin/bash

# set the session to be noninteractive
export DEBIAN_FRONTEND="noninteractive"

# upgrade puppet
wget -q https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
dpkg -i puppetlabs-release-trusty.deb
apt-get update
puppet resource package puppet ensure=3.7.2-1puppetlabs1

# remove the default php
apt-get autoremove -y php*

# fix issue with template dir
sed -e '/templatedir/ s/^#*/#/' -i.back /etc/puppet/puppet.conf

# install a few puppet modules
puppet module install puppetlabs-apt    --version 2.3.0  # https://forge.puppet.com/puppetlabs/apt
puppet module install puppetlabs-apache --version 1.11.0 # https://forge.puppet.com/puppetlabs/apache
puppet module install puppetlabs-mysql  --version 3.10.0 # https://forge.puppet.com/puppetlabs/mysql
