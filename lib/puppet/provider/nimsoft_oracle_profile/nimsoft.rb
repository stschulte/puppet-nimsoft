require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_oracle_profile).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/database/oracle/oracle_monitor.cfg', 'profiles'

  map_property :description, :description
  map_property :connection, :connection
  map_property :source, :alarm_source

  def active
    if value = element[:active]
      value.intern
    else
      :absent
    end
  end

  def active=(new_value)
    element[:active] = new_value.to_s
  end

end
