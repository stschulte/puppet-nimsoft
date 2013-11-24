require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_oracle_connection).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/database/oracle/oracle_monitor.cfg', 'connections'

  map_property :user
  map_property :password
  map_property :description
  map_property :connection, :attribute => :conn_string
  map_property :retry
  map_property :retry_delay
end
