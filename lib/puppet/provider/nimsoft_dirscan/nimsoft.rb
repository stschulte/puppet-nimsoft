require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_dirscan).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/system/dirscan/dirscan.cfg', 'watchers'

  map_property :active, :symbolize => :true
  map_property :description
  map_property :directory
  map_property :pattern
  map_property :recurse, :attribute => :recurse_dirs,  :symbolize => :true
  map_property :direxists, :attribute => :check_dir, :symbolize => true
  map_property :direxists_action, :attribute => :directory_check_command
  map_property :nofiles_action, :attribute => :number_command
  map_property :size_type, :attribute => :file_size_type, :symbolize => true
  map_property :size_action, :attribute => :file_size_command

  def create
    super
    @property_hash[:element][:name] = name
  end

  def nofiles
    if number_condition = element.child('number_condition')
      if limit = number_condition[:limit] and type = number_condition[:type]
        case type.intern
        when :lt
          "< #{limit}"
        when :le
          "<= #{limit}"
        when :gt
          "> #{limit}"
        when :ge
          ">= #{limit}"
        else
          limit
        end
      else
        :absent
      end
    else
      :absent
    end
  end

  def nofiles=(new_value)
    if new_value == :absent
      if number_condition = element.child('number_condition')
        element.children.delete number_condition
      end
    else
      number_condition = element.path('number_condition')
      if match = /^(>=|<=|<|>)?\s*([0-9]+)$/.match(new_value)
        case match.captures[0]
        when '>='
          number_condition[:type] = 'ge'
        when '<='
          number_condition[:type] = 'le'
        when '>'
          number_condition[:type] = 'gt'
        when '<'
          number_condition[:type] = 'lt'
        else
          number_condition[:type] = 'eq'
        end
        number_condition[:limit] = match.captures[1]
      end
    end
  end

  def size
    if size_condition = element.child('file_size_condition')
      if limit = size_condition[:limit] and type = size_condition[:type] and unit = size_condition[:unit]
        case type.intern
        when :le
          "<= #{limit}#{unit.chars.first.upcase}"
        when :ge
          ">= #{limit}#{unit.chars.first.upcase}"
        when :lt
          "< #{limit}#{unit.chars.first.upcase}"
        when :gt
          "> #{limit}#{unit.chars.first.upcase}"
        else
          "#{limit}#{unit.chars.first.upcase}"
        end
      end
    end
  end

  def size=(new_value)
    if new_value == :absent
      if size_condition = element.child('file_size_condition')
        element.children.delete size_condition
      end
    else
      size_condition = element.path('file_size_condition')
      if match = /^(>=|<=|<|>)?\s*([0-9]+)\s*(K|M|G)?$/.match(new_value)
        case match.captures[0]
        when '>='
          size_condition[:type] = 'ge'
        when '<='
          size_condition[:type] = 'le'
        when '>'
          size_condition[:type] = 'gt'
        when '<'
          size_condition[:type] = 'lt'
        else
          size_condition[:type] = 'eq'
        end
        size_condition[:unit] = "#{match.captures[2]}b"
        size_condition[:limit] = match.captures[1]
      end
    end
  end
end
