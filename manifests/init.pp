# Class: nimsoft
# ===========================
#
# Full description of class nimsoft here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'nimsoft':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2018 Your name here, unless otherwise noted.
#
class nimsoft (
  String $domain,
  String $hub,
  Variant $hub_ip,
  String $hub_robot_name      = undef,
  Integer $hub_port,
  Stdlib::Absolutepath $config_file,
  String $package_name,
  String $package_ensure,
  String $service_name,
  String $service_ensure,
  Boolean $service_enable,
  Optional[Variant] $robot_ip = undef,
) {

  file{$config_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    content => template('nimsoft/nms-robot-vars.cfg.erb'),
    notify  => Exec['RobotConfigurer.sh'],
    require => Package[$package_name],
  }

  exec{'RobotConfigurer.sh':
    path        => [ '/bin', '/opt/nimsoft/install', ],
    refreshonly => true,
    notify      => Service[$service_name],
  }

  package{$package_name:
    ensure => $package_ensure,
  }

  service{$service_name:
    ensure  => $service_ensure,
    enable  => $service_enable,
    require => File[$config_file],
  }

}
