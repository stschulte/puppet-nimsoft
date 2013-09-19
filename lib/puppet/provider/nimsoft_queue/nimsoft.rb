require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_queue).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/tmp/hub.cfg', 'postroute'
#  register_config '/opt/nimsoft/hub/hub.cfg', 'postroute'
  map_property :type, :type
  map_property :remote_queue, :remote_queue
  map_property :address, :addr
  map_property :bulk_size, :bulk_size
  map_property :subject, :subject

  def type
    if element and e = element.attributes[:type]
      e.intern
    else
      :absent
    end
  end

  def ensure
    if element and active = element.attributes[:active]
      if active == 'yes'
        :enabled
      else
        :disabled
      end
    else
      :absent
    end
  end

  def ensure=(new_value)
    create unless element
    case new_value
    when :enabled
      element.attributes[:active] = 'yes'
    when :disabled
      element.attributes[:active] = 'no'
    when :absent
      destroy
    end
  end

  def subject
    return :absent unless element and element.attributes[:subject]
    element.attributes[:subject].split(',')
  end

  def subject=(new_value)
    if element
      element.attributes[:subject] = new_value.join(',')
    end
  end

end
