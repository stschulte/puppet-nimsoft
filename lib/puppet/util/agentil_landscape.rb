require 'puppet/util/agentil'

class Puppet::Util::AgentilLandscape

  attr_reader :id, :element

  def initialize(id, element)
    @id = id
    @element = element
    if system_section = @element.child('SYSTEMS')
      @system_ids = system_section.values_in_order.map(&:to_i)
    else
      @system_ids = []
    end
  end

  def name
    @element[:NAME]
  end

  def name=(new_value)
    @element[:NAME] = new_value
  end

  def systems
    @system_ids.map do |id|
      if system = Puppet::Util::Agentil.systems[id]
        system
      else
        raise Puppet::Error, "System with id=#{id} could not be found"
      end
    end
  end

  def company
    @element[:COMPANY]
  end

  def company=(new_value)
    @element[:COMPANY] = new_value
  end

  def sid
    @element[:SYSTEM_ID]
  end

  def sid=(new_value)
    @element[:SYSTEM_ID] = new_value
  end

  def description
    @element[:DESCRIPTION]
  end

  def description=(new_value)
    @element[:DESCRIPTION] = new_value
  end
  
  def assigned_systems
    @system_ids
  end

  def assign_system(system)
    unless @system_ids.include? system
      @system_ids << system
      rebuild_systems_section
    end
  end

  def deassign_system(system)
    if @system_ids.delete(system)
      rebuild_systems_section
    end
  end

  def rebuild_systems_section
    if @system_ids.empty?
      if systems_section = @element.child('SYSTEMS')
        @element.children.delete(systems_section)
      end
    else
      systems_section = @element.path('SYSTEMS')
      systems_section.clear_attr
      @system_ids.each_with_index do |id, index|
        systems_section[sprintf("INDEX%03d", index).intern] = id.to_s
      end
    end
  end
end
