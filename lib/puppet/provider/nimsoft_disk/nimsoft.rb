require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'

  map_property :active, :symbolize => true
  map_property :description
  map_property :device, :attribute => :disk
  map_property :warning, :attribute => :threshold, :section => 'warning'
  map_property :critical, :attribute => :threshold, :section => 'error'
  map_property :warning_enable, :attribute => :active, :section => 'warning'
  map_property :critical_enable, :attribute => :active, :section => 'error'
  map_property :missing, :attribute => :active, :section => 'missing'
end
