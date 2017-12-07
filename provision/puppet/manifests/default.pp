Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

include system-tools
include kernel_blacklist
include apt
include apache2
include php
include mysql-server
