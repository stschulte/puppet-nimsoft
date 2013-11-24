require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_logmon_profile).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/system/logmon/logmon.cfg', 'profiles'

  map_property :active, :symbolize => true
  map_property :file, :attribute => :scanfile
  map_property :mode, :attribute => :scanmode, :symbolize => true
  map_property :interval
  map_property :qos, :symbolize => true
  map_property :alarm, :symbolize => true
  map_property(:alarm_maxserv, :attribute => :max_alarm_sev) do |action, value|
    case action
    when :get
      [ :clear, :info, :warning, :minor, :major, :critical][value.to_i]
    when :set
      [ :clear, :info, :warning, :minor, :major, :critical].index(value).to_s
    end
  end
end
