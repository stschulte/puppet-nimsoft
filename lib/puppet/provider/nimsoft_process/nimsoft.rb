require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_process).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/system/processes/processes.cfg', 'watchers'

  map_property :active, :symbolize => :true
  map_property :trackpid, :attribute => :track_by_pid, :symbolize => :true
  map_property :description
  map_property :alarm_on, :attribute => :report do |action, value|
    case action
    when :get
      value.gsub(/\s/,'').split(',').map(&:intern)
    when :set
      value.map(&:to_s).join(', ')
    end
  end

  def match
    if scan_cmd_line = element[:scan_proc_cmd_line]
      if scan_cmd_line == 'yes'
        :cmdline
      else
        :nameonly
      end
    else
      :absent
    end
  end

  def match=(new_value)
    case new_value
    when :absent
      element.del_attr(:scan_proc_cmd_line)
    when :cmdline
      element[:scan_proc_cmd_line] = 'yes'
    else
      element[:scan_proc_cmd_line] = 'no'
    end
  end

  def pattern
    if resource[:match] and resource[:match] == :cmdline
      element[:proc_cmd_line] || :absent
    else
      element[:process] || :absent
    end
  end

  def pattern=(new_value)
    if resource[:match] and resource[:match] == :cmdline
      element[:proc_cmd_line] = new_value
    else
      element[:process] = new_value
    end
  end

  def count
    if limit = element[:process_count] and type = element[:process_count_type]
      case type.intern
      when :lt
        "< #{limit}"
      when :le, :lte
        "<= #{limit}"
      when :gt
        "> #{limit}"
      when :ge, :gte
        ">= #{limit}"
      else
        limit
      end
    else
      :absent
    end
  end

  def count=(new_value)
    if new_value == :absent
      element.del_attr(:process_count)
      element.del_attr(:process_count_type)
    else
      if match = /^(>=|<=|<|>)?\s*([0-9]+)$/.match(new_value)
        case match.captures[0]
        when '>='
          element[:process_count_type] = 'gte'
        when '<='
          element[:process_count_type] = 'lte'
        when '>'
          element[:process_count_type] = 'gt'
        when '<'
          element[:process_count_type] = 'lt'
        else
          element[:process_count_type] = 'eq'
        end
        element[:process_count] = match.captures[1]
      end
    end
  end
end
