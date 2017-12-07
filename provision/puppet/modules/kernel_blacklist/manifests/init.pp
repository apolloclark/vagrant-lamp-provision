class kernel_blacklist {

    # https://docs.puppet.com/puppet/3.7/type.html#file
    file { '/etc/modprobe.d/blacklist-dccp.conf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/kernel_blacklist/kernel_blacklist.conf'
    }
}