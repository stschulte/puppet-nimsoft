require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_queue).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/hub/hub.cfg', 'postroute'

  map_property :type,         :type
  map_property :remote_queue, :remote_queue
  map_property :address,      :addr
  map_property :bulk_size,    :bulk_size
  map_property :subject,      :subject

  def type
    if element and e = element[:type]
      e.intern
    else
      :absent
    end
  end

  def ensure
    if element and active = element[:active]
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
      element[:active] = 'yes'
    when :disabled
      element[:active] = 'no'
    when :absent
      destroy
    end
  end

  def subject
    return :absent unless element and element[:subject]
    element[:subject].split(',')
  end

  def subject=(new_value)
    if element
      element[:subject] = new_value.join(',')
    end
  end

end
