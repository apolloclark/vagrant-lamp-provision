class php {

  # package install list
  $packages = [
    "php5.6",
    "php5.6-cli",
    "php5.6-common",
    "php5.6-dev",
    "php5.6-gd",
    "php5.6-json",
    "php5.6-mcrypt",
    "php5.6-mysql",
    "php5.6-opcache",
    "php5.6-readline",
    "php5.6-xml",
    "php5.6-zip",
    "pkg-php-tools",
    "dh-php",
    "libapache2-mod-php5.6",
    "php-common",
    "php-pear",
  ]

  apt::ppa { 'ppa:ondrej/php': }
  package { $packages:
    ensure => 'installed',
    require => [
        Class['apt::update'],
        Apt::Ppa['ppa:ondrej/php']
    ]
  }
  file { '/etc/php/5.6/apache2/php.ini':
    ensure => file,
    source => 'puppet:///modules/php/php.ini',
    require => Class['apache2']
  }

  # setup Memory Swap, for PHP Composer
  exec {
    'setup memory swap 1':
        command => '/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024 2>&1',
        require => File['/etc/php/5.6/apache2/php.ini'];
    'setup memory swap 2':
        command => '/sbin/mkswap /var/swap.1 2>&1',
        require => Exec['setup memory swap 1'];
    'setup memory swap 3':
        command => '/sbin/swapon /var/swap.1 2>&1',
        require => Exec['setup memory swap 2'];
  }
  
  # set and run PHP Composer
  exec {
    'PHP Composer update':
        command => 'php composer.phar self-update 2>&1',
        cwd => '/var/www/html',
        environment => "COMPOSER_HOME=/var/www/html",
        require => Exec['setup memory swap 3'];

    'PHP Composer clear':
        command => 'php composer.phar clear-cache 2>&1',
        cwd => '/var/www/html',
        environment => "COMPOSER_HOME=/var/www/html",
        require => Exec['PHP Composer update'];
        
    'PHP Composer install packages':
        command => 'php composer.phar install --no-progress 2>&1',
        cwd => '/var/www/html',
        environment => "COMPOSER_HOME=/var/www/html",
        creates => "${path}/composer.lock",
        require => Exec['PHP Composer clear'];
  }
}
