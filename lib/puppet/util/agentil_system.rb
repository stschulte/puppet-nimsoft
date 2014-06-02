require 'puppet/util/agentil'
require 'puppet/util/agentil_landscape'
require 'puppet/util/agentil_template'
require 'puppet/util/agentil_user'

class Puppet::Util::AgentilSystem

  attr_reader :id, :element, :user_id, :system_template_id

  def self.registry
    Puppet::Util::Agentil
  end

  def registry
    Puppet::Util::Agentil
  end

  def initialize(id, element)
    @id = id
    @element = element
    
    if template_section = @element.child('TEMPLATES')
      @template_ids = template_section.values_in_order.map(&:to_i)
    else
      @template_ids = []
    end

    if system_template_attribute = @element[:DEFAULT_TEMPLATE]
      @system_template_id = system_template_attribute.to_i
    end

    if user_attribute = @element[:USER_PROFILE]
      @user_id = user_attribute.to_i
    end
  end

  def name
    @element[:NAME]
  end

  def name=(new_value)
    @element[:NAME] = new_value
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
    if id = @element[:PARENT_ID]
      if landscape = self.registry.landscapes[id.to_i]
        landscape
      else
        raise Puppet::Error, "Landscape with id=#{id} could not be found"
      end
    else
      raise Puppet::Error, "System does not have a PARENT_ID attribute"
    end
  end

  def landscape=(new_value)
    new_landscape = case new_value
    when Puppet::Util::AgentilLandscape
      new_value
    when Fixnum
      self.registry.landscapes[new_value]
    when String
      self.registry.landscapes.values.find { |l| l.name == new_value }
    end

    raise Puppet::Error, "Landscape #{new_value} not found" unless new_landscape

    if landscape_id = @element[:PARENT_ID]
      self.registry.landscapes[landscape_id.to_i].deassign_system id
    end
      
    new_landscape.assign_system id
    @element[:PARENT_ID] = new_landscape.id.to_s
  end

  def templates
    @template_ids.map do |id|
      if template = self.registry.templates[id]
        template
      else
        raise Puppet::Error, "Template with id=#{id} could not be found"
      end
    end
  end

  def templates=(new_values)
    if new_values.empty?
      if template_element = @element.child('TEMPLATES')
        @element.children.delete(template_element)
        @template_ids.clear
      end
    else
      @template_ids = new_values.map do |new_value|
        template = case new_value
        when Puppet::Util::AgentilTemplate
          new_value
        when Fixnum
          self.registry.templates[new_value]
        when String
          self.registry.templates.values.find { |t| t.name == new_value }
        end

        raise Puppet::Error, "Template #{new_value} not found" unless template
        template.id
      end

      template_element = @element.path('TEMPLATES')
      template_element.clear_attr
      @template_ids.each_with_index do |id, index|
        template_element[sprintf("INDEX%03d", index).intern] = id.to_s
      end
    end
  end

  def system_template
    if @system_template_id
      if template = self.registry.templates[@system_template_id]
        template
      else
        raise Puppet::Error, "System template with id=#{@system_template_id} not found"
      end
    end
  end

  def system_template=(new_value)
    new_system_template = case new_value
    when Puppet::Util::AgentilTemplate
      new_value
    when Fixnum
      self.registry.templates[new_value]
    when String
      self.registry.templates.values.find { |t| t.name == new_value }
    end

    raise Puppet::Error, "Template #{new_value} not found" unless new_system_template


    @system_template_id = new_system_template.id
    @element[:DEFAULT_TEMPLATE] = @system_template_id.to_s
  end

  def user
    if @user_id
      if user = self.registry.users[@user_id]
        user
      else
        raise Puppet::Error, "User with id=#{@user_id} not found"
      end
    end
  end

  def user=(new_value)
    new_user = case new_value
    when Puppet::Util::AgentilUser
      new_value
    when Fixnum
      self.registry.users[new_value]
    when String
      self.registry.users.values.find { |u| u.name == new_value }
    end

    raise Puppet::Error, "Unable to find user #{new_value}" unless new_user

    @user_id = new_user.id
    @element[:USER_PROFILE] = @user_id.to_s
  end
end
