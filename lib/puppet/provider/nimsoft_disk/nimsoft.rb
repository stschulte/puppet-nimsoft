require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_disk).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/system/cdm/cdm.cfg', 'disk/alarm/fixed'

  map_property :active, :symbolize => true
  map_property :nfs, :attribute => :nfs_space_check, :symbolize => true
  map_property :description
  map_property :device, :attribute => :disk
  map_property :missing, :attribute => :active, :section => 'missing', :symbolize => true

  {
    :warning  => 'warning',
    :critical => 'error',
    :delta_error => 'delta_error',
    :delta_warning => 'delta_warning'
  }.each_pair do |property, section_name|
    define_method(property) do
      if section = element.child(section_name)
        if active = section[:active] and threshold = section[:threshold] and active == 'yes'
          threshold
        else
          :absent
        end
      else
        :absent
      end
    end

    define_method("#{property}=".intern) do |new_value|
      section = element.path(section_name)
      if new_value == :absent
        section[:active] = 'no'
      else
        section[:active] = 'yes'
        section[:threshold] = new_value
      end
    end
  end
end
