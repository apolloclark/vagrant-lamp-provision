class apache2 {

    $packages = [
        "libapache2-mod-security2",
    ]
    package { $packages:
        ensure  => present,
        require => Class["system-tools"],
    }
    
    # https://forge.puppet.com/puppetlabs/apache/readme
    # https://github.com/puppetlabs/puppetlabs-apache#beginning-with-apache
    # https://github.com/hollsk/puppet-lamp/blob/master/puppet/manifests/lamp.pp
    class { 'apache':
        default_vhost => false,
        apache_name => 'apache2',
        serveradmin => 'apolloclark@gmail.com',
        servername => '10.0.2.15',
        server_signature => false,
        mpm_module => 'prefork',
    }
    apache::listen { '80': }
    
    # https://forge.puppet.com/puppetlabs/apache/readme#class-apachevhosts
    # https://github.com/puppetlabs/puppetlabs-apache/blob/master/manifests/vhost.pp
    # https://github.com/puppetlabs/puppetlabs-apache/blob/master/examples/vhost.pp#L75
    apache::vhost { 'localhost':
      # ip => '*',
      port => 8081,
      servername => '127.0.0.1',
      serveraliases => [
        '10.0.2.15'
      ],
      docroot => '/var/www/html/public',
      serveradmin => 'apolloclark@gmail.com',
      error_log_file => 'error_log.log',
      access_log_file => 'access_log.log',
      setenv => 'APPLICATION_ENV development',
      headers => 'Set Access-Control-Allow-Origin "*"',
      
      # https://forge.puppet.com/puppetlabs/apache/readme#parameter-directories-for-apachevhost
      # https://github.com/puppetlabs/puppetlabs-apache/blob/master/manifests/vhost.pp#L569
      # https://github.com/puppetlabs/puppetlabs-apache/blob/master/templates/vhost/_directories.erb#L54
      directories => [
        {
          path => '/var/www/html/public',
          directoryindex => 'index.php',
          require => 'all granted',
          allow_override => ['All'],
        }
      ],
    }
    
    # https://forge.puppet.com/puppetlabs/apache#installing-apache-modules
    # https://github.com/puppetlabs/puppetlabs-apache#installing-arbitrary-modules
    class { 'apache::mod::rewrite': }
    class { 'apache::mod::security': }
    # https://forge.puppet.com/puppetlabs/apache#class-apachemodphp
    # https://github.com/puppetlabs/puppetlabs-apache/blob/master/manifests/mod/php.pp
    class { 'apache::mod::php':
        package_name => 'libapache2-mod-php5.6',
        php_version => '5.6'
    }
    
    # https://forge.puppet.com/puppetlabs/apache#defined-type-apachecustom_config
    apache::custom_config { 'localhost':
      source => 'puppet:///modules/apache2/25-localhost.conf',
    }
}