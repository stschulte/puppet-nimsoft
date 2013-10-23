require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'
  map_property :active,          :active
  map_property :description,     :description
  map_property :device,          :disk
  map_property :warning,         :threshold, :section => 'warning'
  map_property :critical,        :threshold, :section => 'error'
  map_property :warning_enable,  :active,    :section => 'warning'
  map_property :critical_enable, :active,    :section => 'error'
  map_property :missing,         :active,    :section => 'missing'

end
