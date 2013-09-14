require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'
  map_fields(
    :active          => 'active',
    :description     => 'description',
    :device          => 'disk',
    :warning         => 'warning/threshold',
    :critical        => 'error/threshold',
    :warning_enable  => 'warning/active',
    :critical_enable => 'error/active',
    :missing         => 'missing/active'
  )

end
