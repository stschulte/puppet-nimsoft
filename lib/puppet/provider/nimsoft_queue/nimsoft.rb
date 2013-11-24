require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_queue).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/hub/hub.cfg', 'postroute'

  map_property :remote_queue
  map_property :address, :attribute => :addr
  map_property :bulk_size
  map_property :subject
  map_property :type, :symbolize => true
  map_property :active, :symbolize => true
  map_property :subject, :symbolize => true
end
