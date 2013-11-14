require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_oracle_connection).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/database/oracle/oracle_monitor.cfg', 'connections'

  map_property :user, :user
  map_property :password, :password
  map_property :description, :description
  map_property :connection, :conn_string
end
