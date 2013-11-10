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
remove any assigned system. So make sure you have appropiate `agentil_system`
resources with `ensure => absent` for every assigned system, too.

#### agentil\_user

The `agentil_user` type can be used to describe a SAP user. The
`sapbasis_agentil` probe needs a designated user to connect to your SAP
systems in order to gether the different metrics. Instead of providing valid
credentials each time you add a SAP system, you can describe one user
that is valid on every system and then simply reference this user in
each of your system definitions. You of course also have one user
for development, quality assurence and production if you like.

Example:

    agentil_user { 'SAP_PROBE':
      ensure   => present,
      password => 'encrypted_password',
    }

*Note*: In order to get the encrypted password you currently have to set the
password in the probe GUI once and check the configuration file afterwards.
When you know the correct encrypted password, you can use puppet to make sure
it stays the same.

#### agentil\_template

The `agentil_template` resource describes a template. A template consists of
a collection of jobs and monitors to easily choose what aspects of your SAP
system you want to monitor. There are actually three types of templates:

1. Templates created by the probe vendor that are shipped with the probe
   itself (the id 1 to 999999 are reserved for these ones)
2. Custom templates starting with id 1000000.
3. System templates

Vendor templates are completly ignored by the `agentil_template` type and you
can only manage custom templates and system template. Here is how they work:
In the probe GUI you can only see 1) and 2) so you will start by creating a
custom template and (un)check the monitors that should apply to your systems.
If you now assign this template to a group of systems, the probe GUI will
implicitly create a system template for each individual system that is
derived from the inital template. You can now define system specific
customizations (e.g. a different threshold for a specific alarm) that
will only modify the system template.

You can now manage both templates through puppet, but be aware that you have
to manage both the initial template and the system templates through puppet
(puppet will not automically create or modify your system templates).

Example:

    agentil_template { 'System template for System sap01':
      ensure    => present,
      system    => 'true',
      monitors  => [ 1, 4, 10, 20, 33 ],
      jobs      => [ 4, 5, 12, 177, 3 ],
    }

The best way to define a template is currently to create the template through
the probe GUI and then run `puppet resource agentil_template` to get the
correct job ids and monitor ids. If you got these, you'll be able to define
appropiate puppet resources.

##### agentil\_system

This resource can be used to describe an agentil system. If you are familiar
with the probe GUI, these are basically your ABAP and SAP connectors and the
second hiearchy level after the landscape.

The agentil system basically tells the probe how to reach an instance and
what jobs and monitors should be used to monitor the instance. To do that
you can define the user that is able to login and the client to connect to.
You can also assign different templates that the probe GUI merges into
a system template (with puppet you have to define both the original template
and the system template).

This can be expressed through puppet now:

Example:

    agentil_system { 'PRO_sap01':
      ensure    => present,
      landscape => 'PRO',
      sid       => 'PRO',
      host      => 'sap01.example.com',
      ip        => '192.168.0.1',
      stack     => 'abap',
      user      => 'SAP_PROBE',
      client    => '000',
      group     => 'LOGON_GROUP_01',
      default   => 'System template for System sap01',
      templates => [
        'Custom ABAP Production',
        'Custom ABAP Generic',
      ]
    }

The landscape, the user and all templates have to be present so the puppet
type is be able translate the names into the corresponding ids to create a
valid configuration file. Puppet will raise an error if a name connot be
found.

Please note that you should provide a system template as the `default`
property and this one is repsponsible to define the actual monitoring tasks.
The system template should also be a correct merge of your non-system
templates you have provided as for the `template` property as these will
be shown in the probe GUI as assigned templates.

##### agentil\_instance

The `agentil_instance` resource can be used to manage the customization of
job 177 (instance availability) of a specified template. Let's assume you
have one SAP System (SID=`PRO`) that consists of three application servers
with two instances each. If you want to monitor the availability of all
instances you'll first assign a template to the message server that includes
job 177 (instance availability). You'll then create one `agentil_instance`
resource for each of your six instances and to make sure they all appear
in the job 177 customization.

Example:

    agentil_instance { 'PRO_sap01_00':
      ensure      => present,
      mandatory   => 'true',
      criticality => 'major',
      autoclear   => 'false',
      template    => 'System template for System sap01'
    }


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

