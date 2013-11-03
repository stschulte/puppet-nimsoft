require 'puppet/util/nimsoft_config'
require 'puppet/util/nimsoft_section'
require 'puppet/util/agentil_landscape'
require 'puppet/util/agentil_user'
require 'puppet/util/agentil_template'

class Puppet::Util::AgentilSystem

  attr_reader :name, :element

  def self.filename
    '/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg'
  end

  def self.initvars
    @config = nil
    @loaded = false
    @systems = {}
  end

  def self.config
    unless @config
      @config = Puppet::Util::NimsoftConfig.add(filename)
      @config.tabsize = 4
    end
    @config
  end

  def self.root
    config.path('PROBE/SYSTEMS')
  end

  def self.parse
    config.parse unless config.loaded?
    @systems = {}
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
    unless @systems.include? name
      if element.nil?
        element_name = "SYSTEM#{root.children.size + 1}"
        element = Puppet::Util::NimsoftSection.new(element_name, root)
      end
      @systems[name] = new(name, element)
    end
    @systems[name]
  end

  def self.del(name)
    if system = @systems.delete(name)
      root.children.delete system.element
      root.children.each_with_index do |child, index|
        child.name = sprintf "SYSTEM%d", index+1
      end
    end
  end

  def self.systems
    parse unless loaded?
    @systems
  end

  def self.genid
    id = 1
    taken_ids = systems.values.map(&:id)
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
  end

  def id
    @element[:ID].to_i
  end

  def host
    @element[:HOST]
  end

  def host=(new_value)
    @element[:HOST] = new_value
  end

  def stack
    if @element[:ABAP_ENABLED] == 'true' and @element[:JAVA_ENABLED] == 'true'
      :dual
    elsif @element[:JAVA_ENABLED] == 'true'
      :java
    else
      :abap
    end
  end

  def stack=(new_value)
    case new_value
    when :dual
      @element[:ABAP_ENABLED] = 'true'
      @element[:JAVA_ENABLED] = 'true'
    when :java
      @element[:ABAP_ENABLED] = 'false'
      @element[:JAVA_ENABLED] = 'true'
    else
      @element[:ABAP_ENABLED] = 'true'
      @element[:JAVA_ENABLED] = 'false'
    end
  end

  def sid
    @element[:SYSTEM_ID]
  end

  def sid=(new_value)
    @element[:SYSTEM_ID] = new_value
  end

  def client
    @element[:ABAP_CLIENT_NUMBER]
  end

  def client=(new_value)
    @element[:ABAP_CLIENT_NUMBER] = new_value
  end

  def group
    @element[:GROUP]
  end

  def group=(new_value)
    @element[:GROUP] = new_value
  end

  def ip
    if ips_element = @element.child('INSTANCE_IPS')
      ips_element.values_in_order
    else
      []
    end
  end

  def ip=(new_value)
    if new_value.empty?
      if ips_element = @element.child('INSTANCE_IPS')
        @element.children.delete(ips_element)
      end
    else
      ips_element = @element.path('INSTANCE_IPS')
      ips_element.clear_attr
      new_value.each_with_index do |ip, index|
        ips_element[sprintf("INDEX%03d", index).intern] = ip
      end
    end
  end

  def landscape
    match = Puppet::Util::AgentilLandscape.landscapes.values.select do |landscape|
      landscape.assigned_systems.include? id
    end.first
    if match
      match.name
    end
  end

  def landscape=(new_value)
    if old_landscape = landscape
      Puppet::Util::AgentilLandscape.landscapes[old_landscape].deassign_system id
    end

    if new_landscape = Puppet::Util::AgentilLandscape.landscapes[new_value]
      new_landscape.assign_system id
      @element[:PARENT_ID] = new_landscape.id.to_s
    else
      raise Puppet::Error, "Landscape #{new_value} not found"
    end
  end

  def templates
    templates = []
    if template_element = @element.child('TEMPLATES')
      template_element.attributes.values.map(&:to_i).each do |assigned_id|
        match = Puppet::Util::AgentilTemplate.templates.values.select do |template|
          template.id == assigned_id
        end.first
        if match
          templates << match.name
        end
      end
    end
    templates
  end

  def templates=(new_value)
    if new_value.empty?
      if template_element = @element.child('TEMPLATES')
        @element.children.delete(template_element)
      end
    else
      assigned_ids = new_value.map do |template_name|
        match = Puppet::Util::AgentilTemplate.templates.values.select do |template|
          template.name == template_name
        end.first
        if match
          match.id
        else
          raise Puppet::Error, "Template #{template_name} cannot be found"
        end
      end
      template_element = @element.path('TEMPLATES')
      template_element.clear_attr
      assigned_ids.each_with_index do |id, index|
        template_element[sprintf("INDEX%03d", index).intern] = id.to_s
      end
    end
  end

  def default
    if @element[:DEFAULT_TEMPLATE] and assigned_id = @element[:DEFAULT_TEMPLATE].to_i
      match = Puppet::Util::AgentilTemplate.templates.values.select do |template|
        template.id == assigned_id
      end.first
      if match
        match.name
      end
    end
  end

  def default=(new_value)
    match = Puppet::Util::AgentilTemplate.templates.values.select do |template|
      template.name == new_value
    end.first
    if match
      @element[:DEFAULT_TEMPLATE] = match.id.to_s
    else
      raise Puppet::Error, "Template #{new_value} not found"
    end
  end

  def user
    if @element[:USER_PROFILE] and assigned_id = @element[:USER_PROFILE].to_i
      match = Puppet::Util::AgentilUser.users.values.select do |user|
        user.id == assigned_id
      end.first
      if match
        match.name
      end
    end
  end

  def user=(new_value)
    match = Puppet::Util::AgentilUser.users.values.select do |user|
      user.name == new_value
    end.first
    if match
      @element[:USER_PROFILE] = match.id.to_s
    else
      raise Puppet::Error, "User #{new_value} not found"
    end
  end
end
