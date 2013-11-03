require 'puppet/util/nimsoft_config'
require 'puppet/util/nimsoft_section'

class Puppet::Util::AgentilLandscape

  attr_reader :name, :element, :assigned_systems

  def self.filename
    '/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg'
  end

  def self.initvars
    @config = nil
    @loaded = false
    @landscapes = {}
  end

  def self.config
    unless @config
      @config = Puppet::Util::NimsoftConfig.add(filename)
      @config.tabsize = 4
    end
    @config
  end

  def self.root
    config.path('PROBE/LANDSCAPES')
  end

  def self.parse
    config.parse unless config.loaded?
    @landscapes = {}
    root.children.each do |element|
      add(element[:NAME], element)
    end
    @loaded = true
  end

  def self.loaded?
    @loaded
  end

  def self.sync
    config.sync
  end

  def self.add(name, element = nil)
    unless @landscapes.include? name
      if element.nil?
        element_name = "LANDSCAPE#{root.children.size + 1}"
        element = Puppet::Util::NimsoftSection.new(element_name, root)
      end
      @landscapes[name] = new(name, element)
    end
    @landscapes[name]
  end

  def self.del(name)
    if landscape = @landscapes.delete(name)
      root.children.delete landscape.element
      root.children.each_with_index do |child, index|
        child.name = sprintf "LANDSCAPE%d", index+1
      end
    end
  end

  def self.landscapes
    parse unless loaded?
    @landscapes
  end

  def self.genid
    id = 1
    taken_ids = landscapes.values.map(&:id)
    while taken_ids.include? id
      id += 1
    end
    id
  end

  def initialize(name, element)
    @name = name
    @element = element
    @element[:NAME] = name
    @element[:ID] ||= self.class.genid.to_s
    @element[:ACTIVE] ||= 'true'
    if system_section = @element.child('SYSTEMS')
      @assigned_systems = system_section.values_in_order.map(&:to_i)
    else
      @assigned_systems = []
    end
  end

  def id
    @element[:ID].to_i
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

  def assign_system(system_id)
    unless @assigned_systems.include? system_id
      @assigned_systems << system_id
      rebuild_systems_section
    end
  end

  def deassign_system(system_id)
    if @assigned_systems.delete(system_id)
      rebuild_systems_section
    end
  end

  def rebuild_systems_section
    if @assigned_systems.empty?
      if systems_section = @element.child('SYSTEMS')
        @element.children.delete(systems_section)
      end
    else
      systems_section = @element.path('SYSTEMS')
      systems_section.clear_attr
      @assigned_systems.each_with_index do |id, index|
        systems_section[sprintf("INDEX%03d", index).intern] = id.to_s
      end
    end
  end
end
