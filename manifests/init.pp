# == Class: puppet_module_nimsoft_installer
#
# Full description of class puppet_module_nimsoft_installer here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'puppet_module_nimsoft_installer':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2016 Your name here, unless otherwise noted.
#
class nimsoft::install (
	$install_probes = "cdm",
	$nimsoft_domain = undef,
	$deploy_addr = undef,
	$hub_list = [],
	$install_source = "repos"
){
	if $::install_nimsoft == 1	#Being careful not to clobber an exising install
	{
		exec
		{
			'/bin/mkdir -p /opt':
				path => ["/usr/bin", "/usr/sbin", "/bin"] 
		} ->
		file
		{
			'/opt/nms-robot-vars.cfg':
				path    => '/opt/nms-robot-vars.cfg',
				ensure  => file,
				content => template('nimsoft_installer/nms-robot-vars.cfg.erb'),
		}

 		if $install_source != "repos"
		{
			if $install_source =~ /^http/
			{
				exec
				{
					'preinstall':
						command	=> "/usr/bin/curl -k -O ${install_source}":
						cwd 	=> '/tmp',
						path	=> ["/usr/bin", "/usr/sbin", "/bin"],
						require	=> File['/opt/nms-robot-vars.cfg'],	
				}
			}
			else
			{
				file 
				{
					"/tmp/${install_source}":
						ensure	=> file,
						owner	=> 'root',
						group	=> 'root',
						mode	=> '0777',
						source	=> "puppet:///modules/nimsoft/${install_source}",
						require	=> File['/opt/nms-robot-vars.cfg'],	
				} ->
				exec
				{
					'preinstall':		#This hack exploits resource ordering and the fact that
								#this resource will not be defined until runtime. Since
								#resource ordering is not robust enough to go by class
								#name only, but includes the resource type too, this is
								#needed to make sure we have completed preinstall and
								#the needed installer is present.
						command	=> "/bin/echo hack >> /dev/null":
						path	=> ["/usr/bin", "/usr/sbin", "/bin"],

				}
			}

			if $install_source =~ /\.rpm$/ or $install_source =~ /\.deb$/
			{
				if $install_source =~ /\.rpm$/
				{
					$provider = "rpm"
				}
				if $install_source =~ /\.deb$/
				{
					$provider = "dpkg"
				}

				package
				{
					'nimsoft-robot':
						ensure		=> present,
						provider	=> $provider,
						source		=> "/tmp/${source}"
						require		=> Exec['preinstall']
						before          => File['/opt/nimsoft/request.cfg']
				}
			}
			else
			{
				if $::hardwaremodel == "x86_64" { $arch = "_64" }
				file
				{
					path	=> /tmp/${install_source},
					ensure	=> present,
					mode	=> '0777',
					require	=> Exec['preinstall']
				} ->
				exec
				{
					"/bin/tar -xvzf /tmp/${install_source} LINUX_23$arch/nimldr":
						path => ["/usr/bin", "/usr/sbin", "/bin"]			
				} ->
				exec
				{
					"/tmp/nimldr &":
						path => ["/usr/bin", "/usr/sbin", "/bin"],
						before          => File['/opt/nimsoft/request.cfg']
				}	
			}
		}
		else
		{
			package
			{
				'nimsoft-robot':
					ensure		=> present,
					before		=> File['/opt/nimsoft/request.cfg']
			}
		}

		file
		{
			'/opt/nimsoft/request.cfg':
				path    => '/opt/nimsoft/request.cfg',
				ensure  => file,
				content => template('nimsoft_installer/request.cfg.erb'),
		} ->		
		exec
		{
			'/bin/bash /opt/nimsoft/install/RobotConfigurer.sh':
				path	=> ["/usr/bin", "/usr/sbin", "/bin"],
		} ->
		exec
		{
			'/bin/mkdir -p /opt/nimsoft/scripts /opt/nimsoft/probes/system/cdm':
				path	=> ["/usr/bin", "/usr/sbin", "/bin"],
		} ->
		file 
		{
			'/opt/nimsoft/scripts/restart.sh':
				ensure => file,
				owner  => 'root',
				group  => 'root',
				mode   => '0755',
				source => 'puppet:///modules/nimsoft/restart_probe.sh',
		} ->	
		exec
		{
			"sed -i -e 's#</controller>#   deploy_addr = ${deploy_addr}\\n</controller>#g' /opt/nimsoft/robot/robot.cfg":
				path => ["/usr/bin", "/usr/sbin", "/bin"],
				before	=> Service['nimbus']
		}
	}

	service
	{
		'nimbus':
			ensure => running,
			enable => true
	}
}
