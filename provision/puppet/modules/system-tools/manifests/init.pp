class system-tools {

  exec { 'apt-get update':
    command => 'apt-get update',
  }

  $packages = [
	"build-essential",
	"software-properties-common",
	"nano",
	"python-software-properties",
	"mlocate",
	"supervisor",
	"openssh-server",
	"iftop",
	"nmap",
	"git",
	"unzip",
	"zip",
  ]
  package { $packages:
    ensure => "installed",
    require => Exec['apt-get update'],
  }
}