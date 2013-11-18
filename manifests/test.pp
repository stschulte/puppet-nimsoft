#nimsoft_disk { '/UX_Server':
#  ensure => absent,
#}
#
#nimsoft_disk { '/control':
#  ensure => present,
#  active => no,
#}
#
#nimsoft_disk { '/volumes/dbcp3dg/sapdata1':
#  ensure   => present,
#  warning  => 90,
#  critical => 95,
#}

nimsoft_queue { 'RE-HUB-alarm':
  ensure  => enabled,
  type    => attach,
  subject => 'alarm'
}

nimsoft_queue { 'RE-HUB-qos':
  ensure       => enabled,
  type         => attach,
  subject      => [ 'QOS_MESSAGES', 'QOS_DEFINITIONS' ],
}

