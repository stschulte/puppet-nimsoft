Puppet Nimsoft Module
=====================

[![Build Status](https://travis-ci.org/stschulte/puppet-nimsoft.png?branch=master)](https://travis-ci.org/stschulte/puppet-nimsoft)


What is Nimsoft?
----------------

Nimsoft Monitoring is a monitoring solution from CA Technologies.

If you want to monitor a service with nimsoft, you'll first have to install a
robot (the agent software) on your target machine or on a proxy machine (in
case of agentless monitoring). Once the connection between the robot and your
master server (or nearest nimsoft hub) is established, you can deploy probes
onto your robot to monitor a specific service.

Each probe that you deploy on a robot is responsible for one or more dedicated
areas like checking disk and cpu utilization (`cdm` probe) or parsing logfiles
for errors (`logmon` probe). Most probes will gather quality of server metrics
(e.g. publish the current disk utilization every 5 minutes) and can also be
configured to send alarms once a certain threshold is exceeded (e.g. one disk
is more than 90% full). Each probe is independet from another and will run as a
seperate process on your target machine.

The configuration of these probes are stored in flat configuration files
(`<probename>.cfg`) and are always local to the server you want to monitor.

This is important for puppet to be able to change the monitoring policy
for one server locally.


Why managing nimsoft through puppet?
------------------------------------
The ultimate goal is free the administrator of any repetitive task that
might occure when a new server is provisioned or decomissioned. The second
goal is use the available puppet infrastructure (e.g. `hiera`) to give the
consumers of your monitoring landscape the ability to tweak certain aspects
of your monitoring configuration.

Imagine you want to run an apache webserver and you already use puppet
to make sure that the `apache` package is installed and the correct
apache configuration files or vhosts are in place. To setup the
monitoring for this new website you need information that you
probably already have in puppet, like the name of the vhost instance
or the port your vhost is listening on (e.g. to monitor the website
with the `netconnect` probe and parsing error logs with the `logmon`
probe).

So instead of seperating the provisioning process and the monitoring
configuration, you will now be able combine both, so the `apache` puppet
class will automatically configure the necessary probes to setup the
monitoring.

This goal can be archived by expressing monitoring rules as puppet
resources and this repository tries to deliver these resources.

New facts
---------
(currently none)

New functions
-------------
(currently none)

New custom types
----------------

### nimsoft core probes

#### nimsoft\_disk

The `nimsoft_disk` type can be used to describe a filesystem you want to
monitor. It will modify the `disk/alarm/fixed` section of your `cdm`
configuration file. Example:

Make sure a certain device is not monitored:

    nimsoft_disk { '/dev':
      ensure => absent,
    }

Set explicit thresholds on another device:

    nimsoft_disk { '/var':
      ensure   => present,
      warning  => 20,
      critical => 10,
    }

deactivate the warning threshold and make sure to raise an alarm when
the device is absent

    nimsoft_disk { '/var/lib/mysql':
      ensure   => present,
      warning  => absent,
      critical => '10'
      missing  => 'yes',
    }

The `nimsoft_*` types all implement an `instances` method so
you can run `puppet resource nimsoft_disk` on a machine with the cdm probe
installed and see a list of all relevant parameters and how puppet interprets
the current configuration file.

#### nimsoft\_queue

The `nimsoft_queue` type can be used to describe a queue on your hub.

    nimsoft_queue { 'HUB-alarm':
      ensure  => present,
      active  => yes,
      type    => attach,
      subject => 'alarm',
    }

#### nimsoft\_dirscan

The `nimsoft_dirscan` type can be used to describe a profile for the
`dirscan` probe. It can be used to check the size of a file or a group
of files and can also be used to check the number of files in a given
directory (and optional all subdirectories).

Possible usecase: You deploy an application with puppet and this application
writes a specific logfile. You now want nimsoft to trigger an alarm if this
logfile exceeds a certain size limit (e.g. you expect the size to be less than
10 megabytes). You also want to trigger an alarm if the logdirectory or the
logfile is absent:

    nimsoft_dirscan { 'foo logfile':
      ensure      => present,
      active      => yes,
      description => 'Check debug.log of application foo'
      directory   => '/opt/foo/log',
      pattern     => 'debug.log',
      recurse     => 'no',
      direxists   => 'yes',
      nofiles     => '1',
      size        => '< 10M'
    }

#### nimsoft\_logmon\_profile

The `nimsoft_logmon_profile` type can be used to describe a profile for
the `logmon` probe. The logmon probe is able to monitor a logfile, to
execute a command and check its error code, or to check a url. The
`nimsoft_logmon_profile` type can currently only be used to monitor
a logfile.

Example:

    nimsoft_logmon_profile { 'system log':
      ensure       => present,
      active       => yes,
      file         => '/var/log/messages',
      mode         => updates,
      qos          => no,  # do not generate Quality of Service messages
      alarm        => yes, # allow creation of alarm messages
      alarm_maxsev => critical,
    }

Note that you are only defining the general profile here. You also
have to add watcher rules for your profile. You can do that with
an upcoming `nimsoft_logmon_watcher` resource type

#### nimsoft\_logmon\_watcher

The `nimsoft_logmon_watcher` type can be used to describe a watcher rule for
a specific logmon profile. A watcher rule describes a pattern that can appear
in a logfile and describes the message that will be sent, if such an
entry appears. A watcher rule does always belong to exactly one profile.

Example:

    nimsoft_logmon_watcher { 'system log/failed root login'
      ensure   => present,
      active   => yes,
      match    => '/FAILED su for root by (.*)/',
      message  => 'Possible breakin attempt detected: ${msg}',
      severity => 'warning',
    }

The name of the resource must be of the for `profile_name/watcher_name`.

#### nimsoft\_process

The `nimsoft_process` type can be used to describe a profile for the proceses
probe. Example:

    nimsoft_process { 'cron':
      ensure      => present,
      description => 'Make sure cron is running (managed by puppet)',
      active      => yes,
      pattern     => '/usr/sbin/cron',
      match       => nameonly,
      trackpid    => yes,
      count       => '>= 1',
      alarm_on    => [ 'down', 'restart' ],
    }

### oracle probe

#### nimsoft\_oracle\_connection

The `nimsoft_oracle_connection` can be used to describe a database connection
that can be used by the `oracle` probe to monitor your oracle database
instances. Example:

    nimsoft_oracle_connection { 'PROD':
      ensure      => present,
      description => 'The productional database',
      connection  => 'host.example.com:1521/PROD', # or some tnsnames.ora entry
      user        => 'nmuser',
      password    => 'secret',
      retry       => '0',
      retry_delay => '10 sec',
    }

The connection string can either be a service entry that can be resolved
through the `tnsnames.ora` file or an easy connect string of the form
`host[:port]/service_name`.

#### nimsoft\_oracle\_profile

The `nimsoft_oracle_profile` type can be used to describe a monitoring
profile that is used to monitor a database instance. You cannot define custom
checkpoints at the moment so every new profile that is created through puppet
will inherit all monitoring options form your template. You can however define
custom checkpoints in the `oracle` probe GUI and puppet will not destroy these.


Example:

    nimsoft_oracle_profile { 'PROD':
      ensure      => present,
      active      => yes,
      description => 'Billing database',
      connection  => 'PROD',
      source      => 'host.example.com',
      heartbeat   => '5 sec',
      interval    => '5 min',
    }


Hint: If the connection name of your `nimsoft_oracle_profile` instance matches
the name of a `nimsoft_oracle_connection` resource, the `connection` will be
autorequired and you do not have to define an explicit require.

### Agentil probe

The `sapbasis_agentil` probe can be used to monitor SAP instances. The probe
is available trough CA but has been developed by Agentil.

While the probe shares the same configuration file format as any other nimsoft
probe (note: this is about to change and new versions use json as a
configuration format) the configuration file is very special in how it
represents arrays (e.g. one system can be assigned to more than one
template) and references (e.g. system definition can reference a user definition)

This way it is nearly impossible to use the native nimsoft deployment mechanism
to make configuration changes.

The custom types for handling different aspects of your `sapbasis_agentil` allow
a very abstract view of the configuration file and are able to add/remove/modify
systems and landscapes and creating the necessary relationships.

#### agentil\_landscape

The `agentil_landscape` type can be used to describe a landscape (a landscape
is like a container and describes one system identifier. Each landscape
can consist of one or more systems). If you are familiar with the
`sapbasis_agentil` probe interface, a landscape represents the first
hierarchy level inside the configuration GUI.

    agentil_landscape { 'sapdev.example.com'
      ensure      => present,
      sid         => 'DEV'
      company     => 'My Company'
      description => 'managed by puppet',
    }

The above example will make sure that the `sapdev.example.com` landscape
exists and that properties like system identifier, company, and description
have the correct value. Please note that if you set `ensure => absent`,
puppet will make sure that the landscape is absent but will not automatically
remove any assigned system. So make sure you have appropiate `agentil_system`
resources with `ensure => absent` for every assigned system, too.

#### agentil\_user

The `agentil_user` type can be used to describe a SAP user. The
`sapbasis_agentil` probe needs a designated user to connect to your SAP
systems in order to gather the different metrics. Instead of providing valid
credentials each time you add a SAP system, you can describe one user
that is valid on every system and then simply reference this user in
each of your system definitions. You can also create multiple users if
you want to use different credentials for production and developlment boxes
for example.

Example:

    agentil_user { 'SAP_PROBE':
      ensure   => present,
      password => 'encrypted_password',
    }

*Note*: The password encryption algorithm is not public. In order to get the encrypted
password you currently have to set the password in the probe GUI manually and then check
the configuration file afterwards. Once you know the encrypted reprensentation of your
password, you can use puppet to make sure it stays the same.

#### agentil\_template

The `agentil_template` resource describes a template. A template consists of
a collection of jobs and monitors to easily choose what aspects of your SAP
system you want to monitor. There are three types of templates:

1. Templates created by the probe vendor have an id between 1 and
   999999 and are shipped together with the probe
2. Custom templates starting with id 1000000. These are normally
   created with the probe UI
3. System templates which are implicit and cannot be seen directly in the
   probe UI. A system templates inherits the monitors and jobs from the
   assigned vendor and custom templates and also hold system specific
   customizations. Each system has exactly one system template

The puppet type `agentil_template` currently ignores vendor templates completly
but can be used to create custom templates and system templates. If you specify
a system template you should not set `jobs` and `monitors` explicitly since these
are inherited from the assigned templates. But you can use the `agentil_template`
type to establish customizations like custom tablespace utilization thresholds.

Example:

    agentil_template { 'Custom Template':
      ensure    => present,
      system    => false,
      monitors  => [ 1, 4, 10, 20, 33 ],
      jobs      => [ 4, 5, 12, 177, 3 ],

    agentil_template { 'System template for System sap01':
      ensure             => present,
      system             => true,
      expected_instances => [ 'PRO_sap01_00', 'PRO_sap01_01' ],
      tablespace_used    => {
        'PSAPSR3'  => '80',
        'PSAPUNDO' => '98',
      },
    }

Again you can use `puppet resource agentil_template` on a system with a
configured `sapbasis_agentil` probe and see how puppet interprets your
configuration file.


#### agentil\_system

This resource can be used to describe an agentil system. If you are familiar
with the probe GUI, these are basically your ABAP and SAP connectors and the
second hiearchy level after the landscape.

The agentil system basically tells the probe how to reach an instance and
what jobs and monitors should be used to monitor the instance. To do that
you can define the user that is able to login and the client to connect to.
You can also assign different templates that the probe GUI merges into
a system template (with puppet you have to define both the original template
and the system template).

Example:

    agentil_system { 'PRO_sap01':
      ensure          => present,
      landscape       => 'PRO',
      sid             => 'PRO',
      host            => 'sap01.example.com',
      ip              => '192.168.0.1',
      stack           => 'abap',
      user            => 'SAP_PROBE',
      client          => '000',
      group           => 'LOGON_GROUP_01',
      system_template => 'System template for System sap01',
      templates       => [
        'Custom ABAP Production',
        'Custom ABAP Generic',
      ]
    }

The landscape, the user and all templates have to be present so the puppet
type is be able translate the names into the corresponding ids to create a
valid configuration file. Puppet will raise an error if a name connot be
found.

Complete examples
-----------------

Helper scripts
--------------

After you make configuration changes you have to restart the probe. So if puppet
modifies a file, it'll also have to restart the effected probe. You can use the
`restart_probe.sh` script to do that (you can find it in the `files` directory).
You may want to use it inside a manifest, e.g.

    # Make sure the script is present on your robot
    file { '/opt/nimsoft/scripts/restart.sh':
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/nimsoft/restart.sh',
    }

    # Define an exec resource with refreshonly
    exec { 'restart_cdm_probe':
      command     => '/opt/nimsoft/scripts/restart.sh cdm',
      refreshonly => true
    }

    # Trigger the exec resource if something changes
    nimsoft_disk { '/dev':
      ensure => absent,
      notify => Exec['restart_cdm_probe']
    }

Running the tests
-----------------

This project requires the `puppetlabs_spec_helper` gem (available on rubygems.org)
to run the spec tests. You can run them by executing `rake spec`.

Develop a new type and provider
-------------------------------
The nimsoft providers all work pretty similar:

1. Read the configuration file and convert it into a tree structure. All
   resources can be checked very efficiently against this
   in-memory-representation of your configuration.
2. If a resource is out of sync, the tree is modified and written back to
   disk.

Parsing configuration files is done by the `Puppet::Util::NimsoftConfig`
class. Here is simple way to parse a configuration file:

    config = Puppet::Util::NimsoftConfig.add('cdm.cfg') # should be an absolute path
    config.parse unless config.loaded?

The first line will either create a new `Puppet::Util::NimsoftConfig` object or -
if the file was already added before - will return an already present object that
represents the configuration file. This way seperate providers can modifiy the
same configuration file and modifications of the tree structure of provider 1
can directly be seen by provider 2, thus eleminating the need to parse the
configuration file multiple times. So you can e.g. create a `cdm_disk` and a
`cdm_cpu` provider both managing the `cdm.cfg` file at the same time.

If you want to develop a new provider for a new custom type you should
inherit from the `Puppet::Provider::Nimsoft` provider

Let's take the `nimsoft_disk` as a step by step example. You'll first have to
create the basic sketch of your provider:

    require 'puppet/provider/nimsoft'
    Puppet::Type.type(:nimsoft_cdm_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do
      register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'
    end

The `register_config` method is inherited from the `Puppet::Provider::Nimsoft`
provider and will trigger the parsing of the specified configuration file
and will take the specified section as the rootsection for your provider.

Each subsection within that new root section is processed as a new instance
of your custom type. The element title will be the `name` of that instance.

At a class level you can use the classs method `root` to get a
`Puppet::Util::NimsoftSection` object that represents the root section you
have defined earlier and `config` to get the representation the whole
configuration file.

Each provider instance can use the method `element` to get the subtree that
is mapped to the specific provider instance.

You can modify the tree as you like and then run the class method
`config.sync` to save your changes back to disk.

In case each section within your `root` section represents a provider
instance and in case your resource properties are simple attributes within
these sections, you can use the method `map_property` to save you a lot of
typing and create getter and setter methods.

E.g. for our `nimsoft_disk` type every section within the root section `disk/alarm/fixed` represents
one disk. The `description` attribute of each subsection can be mapped to a `description` property of
our custom type, so let's modify our provider:

    require 'puppet/provider/nimsoft'
    Puppet::Type.type(:nimsoft_cdm_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do
      register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'
      map_property :description
    end

If the property name is different from the attribute name, we can define a custom attribute
name.

    require 'puppet/provider/nimsoft'
    Puppet::Type.type(:nimsoft_cdm_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do
      register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'
      map_property :description
      map_property :device, :attribute => :disk
    end

We can also define a section within the subtree:

    require 'puppet/provider/nimsoft'
    Puppet::Type.type(:nimsoft_cdm_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do
      register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'
      map_property :description
      map_property :device, :attribute => :disk
      map_property :warning, :section => 'warning', :attribute => :threshold
      map_property :critical, :section => 'error', :attribute => :threshold
    end

and we can also instruct the provider to symbolize the attribute value:

    require 'puppet/provider/nimsoft'
    Puppet::Type.type(:nimsoft_cdm_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do
      register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'
      map_property :description
      map_property :device, :attribute => :disk
      map_property :warning, :section => 'warning', :attribute => :threshold
      map_property :critical, :section => 'error', :attribute => :threshold
      map_property :active, :symbolize => true
      map_property :missing, :attribute => :active, :section => 'missing', :symbolize => :yes
    end
