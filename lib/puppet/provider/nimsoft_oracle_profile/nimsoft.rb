require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_oracle_profile).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/database/oracle/oracle_monitor.cfg', 'profiles'

  map_property :active, :symbolize => true
  map_property :description
  map_property :connection
  map_property :source, :attribute => :alarm_source
  map_property :interval
  map_property :heartbeat
  map_property :clear_msg, :attribute => :tout_clear
  map_property :sql_timeout_msg, :attribute => :sql_tout_msg
  map_property :profile_timeout_msg, :attribute => :p_tout_msg
  map_property :severity, :attribute => :p_tout_sev, :symbolize => true
  map_property :connection_failed_msg, :attribute => :con_fail_msg
  map_property :sql_timeout
  map_property :profile_timeout, :attribute => :p_timeout
end
