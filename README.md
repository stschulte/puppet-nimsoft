Puppet Nimsoft Module
=====================

[![Build Status](https://travis-ci.org/stschulte/puppet-nimsoft.png?branch=master)](https://travis-ci.org/stschulte/puppet-nimsoft)


What is Nimsoft?
----------------

Nimsoft Monitoring is a monitoring solution from CA Technologies.

The basic pattern to monitor your server is to first install a
robot (the agent software) on your target machine and once the connection
to your master server (or nearest hub) is established, you can deploy probes
onto your server. Each probe is repsonsible for a one or more dedicated
areas like checking disk utilization (`cdm` probe) or parsing logfiles
(`logmon` probe). A probe will most likely gather quality of service
metrics (e.g. current disk utilization every 5 minutes) and send alarms
when certain thresholds are exceeded (e.g. disk more than 90% full). Each probe
is independet from another and will run as a seperate executable on the
target machine.

The configuration of these probes is stored in flat configuration files
(`<probename>.cfg`) and is always local to the server you want to monitor.

Why managing nimsoft through puppet?
------------------------------------
The aim of this repository is to publish puppet types and providers to
be able to manage specific parts of your probe configuration files as
puppet resources.

Imagine you run a webserver with apache and naturally you use puppet
to make sure that the `apache` package is installed and the correct
apache configuration files or vhosts are in place. Theres a good chance
that the all the information needed to monitor your webserver through
nimsoft is already available inside your apache module, e.g. the
name of your `vhost` or the port your application is listening on,
so it makes sense to hook your monitoring into your puppet manifests
(e.g. checking your application with the `netconnect` probe and parsing
your error logs with the `logmon` probe).

So instead of seperating the provisioning process and the monitoring
configuration, you will be able combine both, so the `apache` puppet
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

Set different thresholds on another device:

    nimsoft_disk { '/var':
      warning => 10,
      error   => 20,
    }

Use `puppet resource nimsoft_disk` on a machine with the cdm probe installed
to get a list of all parameters.

#### nimsoft\_queue

The `nimsoft_queue` type can be used to describe a queue on your hub.

    nimsoft_queue { 'HUB-alarm':
      ensure  => enabled,
      type    => attach,
      subject => 'alarm',
    }

### Agentil probe

Agentil has developed the `sapbasis_agentil` probe that is able to monitor all
your SAP instances. While the `sapbasis_agentil` configuratio file follows the
same rules as any other nimsoft configuration file, it is special in the way
how it handles arrays (e.g. one system can be assigned to more than one
template) and it is able to establish references between landscapes, systems,
users and templates by assiging numerical IDs to every landscape, system, etc.
This way it is nearly impossible to use the native nimsoft deployment mechanism
by overwriting cfg files with cfx files.

The custom types for handling different aspects of your `sapbasis_agentil`
configuration file however is able to establish relationships, remove systems
and landscapes, generating new ids for new systems etc.

#### agentil\_landscape

The `agentil_landscape` type can be used to describe a landscape (a landscape
is like a container and describes one system identifier. Each landscape
can consist of one or more systems). If you are familiar with the
`sapbasis_agentil` probe interface, a landscape represents the first
hierarchy level inside the configuratio GUI.

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
remove any assigned system.

#### Complete example

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

