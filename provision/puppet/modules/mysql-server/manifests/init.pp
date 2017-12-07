class mysql-server {

  # https://forge.puppet.com/puppetlabs/mysql/readme
  # https://github.com/puppetlabs/puppetlabs-mysql
  
  # https://forge.puppet.com/puppetlabs/mysql/readme#mysqlclient
  class { 'mysql::client':
    package_name => 'mysql-client-5.6', # https://forge.puppet.com/puppetlabs/mysql/readme#package_name-1
    package_ensure => '5.6.33-0ubuntu0.14.04.1', # https://forge.puppet.com/puppetlabs/mysql/readme#package_ensure-1
    require => Class['::mysql::server'],
  }

  # https://forge.puppet.com/puppetlabs/mysql/readme#mysqlserver
  class { 'mysql::server':
    package_name => 'mysql-server-5.6', # https://github.com/puppetlabs/puppetlabs-mysql#package_name
    package_ensure => '5.6.33-0ubuntu0.14.04.1', # https://github.com/puppetlabs/puppetlabs-mysql#package_ensure
    service_name => 'mysql',
    config_file => '/etc/mysql/my.cnf',
    # remove_default_accounts => 'true',
    root_password => 'root',
    
    # https://forge.puppet.com/puppetlabs/mysql/readme#grants
    # https://github.com/puppetlabs/puppetlabs-mysql/blob/master/spec/unit/puppet/type/mysql_grant_spec.rb
    grants => {
      'root@%/*.*' => {
        ensure => 'present',
        options => ['GRANT'],
        privileges => ['ALL'],
        table => '*.*',
        user => 'root@%',
      },
    },
    override_options => {
      mysqld => { bind-address => '0.0.0.0'} #Allow remote connections
    },
  }
    
  # https://forge.puppet.com/puppetlabs/mysql/readme#mysqldb
  mysql::db { 'testdb':
    user => 'test-user',
    password => 'H7SCw60iKG2jjW%G',
    host => 'localhost',
    sql => '/vagrant/database/database.sql'
  }
  
  # https://forge.puppet.com/puppetlabs/mysql/readme#mysqlbindings
  class{ 'mysql::bindings':
    php_enable => 'true'
  }
}