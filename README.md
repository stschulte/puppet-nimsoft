Puppet Nimsoft Module
=====================

Nimsoft Monitoring is a monitoring solution from CA Technologies.

The basic pattern to monitor your server is to first install a
robot (the agent) on your target system and second deploy probes
that are responsible for gathering metrics and sending alarms about
specific monitor areas (e.g. the `cdm` probe, that monitors CPU, disk,
and memory or the `logmon` probes that can analyse logfiles and
searching for patterns)

The configuration of these probes is stored in flat configuration files
and is always local to the server you want to monitor.

This aim of this repository is to publish puppet types and providers to
be able to manage specific parts of your probe configuration files as
puppet resources.

Example:
You run an apache webserver on your host and you deploy the apache
package and configuration with puppet. So inside your puppet manifest
you most likely already have all the information you'd need to setup your
monitoring, e.g. making the sure you have a certain profile in your
logmon probe activated to parse the apache error log.

Instead of seperating the provisioning process and the monitoring
configuration you should conbine it, so the `apache` puppet class should
be able to automatically configure the necessary probes to setup the
monitoring.


New facts
---------
(currently none)

New functions
-------------
(currently none)

New custom types
----------------

## nimsoft\_disk

The `nimsoft_disk` type can be used to describe a filesystem you want to
monitor. It will modify the `disk/alarm/fixed` section of your configuration
file. Example:

Make sure a certain device is not monitored:

    nimsoft_disk { '/dev':
      ensure => absent,
    }

Set different thresholds

    nimsoft_disk { '/var':
      warning => 10,
      error   => 20,
    }

Use `puppet resource nimsoft_disk` on a machine with the cdm probe installed
to get a list of all parameters.

Develop a new type and provider
-------------------------------
The nimsoft providers all work pretty similar:

1. Read the configuration file and convert it into a tree structure. All
   resources can be checked very efficiently against this
   in-memory-representation of your configuration.
2. If a resource is out of sync, the tree is modified and written back to
   disk.

But you may also encounter the sitation of two providers managing the same
configuration file, like a `cdm_disk` provider and `cdm_cpu` provider both
managing the `cdm.cfg` file. So you also have to be able to share the
in-memory-representation of your configuration files among different
providers.

This is all done by the generic `Puppet::Provider::Nimsoft` provider that
you should enherit from. Let's take the `cdm_disk` as a step by step example.
You'll first have to create the basic sketch of your provider:

    require 'puppet/provider/nimsoft'
    Puppet::Type.type(:nimsoft_cdm_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do
      register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'
    end

The `register_config` method is inherited from the `Puppet::Provider::Nimsoft`
provider and will trigger the parsing og the specified configuration file
and will take the specified section as the rootsection for your provider. You
should never have two providers managing the same section. If more than one
provider handles the same configuration file it is only loaded once.

Your provider also has the class method `section` which will return the
specified `Puppet::Util::NimsoftSection` you have passed to the `register_config`
method and each provider has the instace method `element` which will return
the subtree that is specific to a certain provider instance. You can modify
the tree as you like and can then run the class method `config.sync` to save
your changes to disk.

But in most cases you don't need all this and can just specify how your puppet
properties map to a tree object. You can do this with the `map_fields`
method which will create getter and setter methods for your properties that
will return or modify the corresponding elements in your tree:

    require 'puppet/provider/nimsoft'
    Puppet::Type.type(:nimsoft_cdm_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do
      register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'
      map_fields :active   => 'active'
      map_fields :warning  => 'warning/threshold'
      map_fields :critical => 'error/threshold'
    end

