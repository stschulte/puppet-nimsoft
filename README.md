Puppet Nimsoft Module
=====================

[![Build Status](https://travis-ci.org/stschulte/puppet-nimsoft.png?branch=master)](https://travis-ci.org/stschulte/puppet-nimsoft)


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

## nimsoft\_queue

The `nimsoft_queue` type can be used to describe a queue for your hub.

    nimsoft_queue { 'HUB-alarm':
      ensure  => enabled,
      type    => attach,
      subject => 'alarm',
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
class. Here is simple way to request a file:

    config = Puppet::Util::NimsoftConfig.add('cdm.cfg') # should be an absolute path
    config.parse unless config.loaded?

The first line will either create a new `Puppet::Util::NimsoftConfig` object or -
if the file was already added before - will return an already present object that
represents our configuration file. This way seperate providers can modifiy the
same configuration file and modifications of the tree structure of provider 1
can directly be seen by provider 2, thus eleminating the need to parse the
configuration file multiple times. So you can e.g. create a `cdm_disk` and a
`cdm_cpu` provider both managing the `cdm.cfg` file.

If you want to develop a new provider for a new custom type you should
inherit from the `Puppet::Provider::Nimsoft` provider

Let's take the `cdm_disk` as a step by step example. You'll first have to
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
have defined earlier and `config` to get the representation of your
configuration file.

Each provider instance can use the method `element` to get the subtree that
is mapped to the provider instance.

You can modify the tree as you like and then run the class method
`config.sync` to save your changes back to disk.

In case each section within your `root` section represents a provider
instance and in case your resource properties are simple attributes within
these sections, you can use the method `map_fields` to save you a lot of
typing and create getter and setter methods.

    require 'puppet/provider/nimsoft'
    Puppet::Type.type(:nimsoft_cdm_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do
      register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'
      map_fields :active,   :active
      map_fields :warning,  :threshold, :section => 'warning'
      map_fields :critical, :threshold, :section => 'error'
    end

