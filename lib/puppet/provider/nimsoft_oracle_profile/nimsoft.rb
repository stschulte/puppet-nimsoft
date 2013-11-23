require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_oracle_profile).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/database/oracle/oracle_monitor.cfg', 'profiles'

  map_property :active, :symbolize => true
  map_property :description
  map_property :connection
  map_property :source, :attribute => :alarm_source
  map_property :interval
  map_property :heartbeat
end
