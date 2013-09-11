Puppet Nimsoft Module
====================

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
you most likely already have all the information you need to setup your
monitoring, e.g. making the sure that you have a certain profile in your
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
(currently none)

