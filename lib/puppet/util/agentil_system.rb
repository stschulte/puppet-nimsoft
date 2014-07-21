require 'puppet/util/agentil'
require 'puppet/util/agentil_landscape'
require 'puppet/util/agentil_template'
require 'puppet/util/agentil_user'

class Puppet::Util::AgentilSystem

  attr_reader :id, :element, :user_id, :system_template_id

  def initialize(id, element)
    @id = id
    @element = element
    
    if template_section = @element['TEMPLATES']
      @template_ids = template_section.map(&:to_i)
    else
      @template_ids = []
    end

    if system_template_attribute = @element['DEFAULT_TEMPLATE']
      @system_template_id = system_template_attribute.to_i
    end

    if user_attribute = @element['USER_PROFILE']
      @user_id = user_attribute.to_i
    end
  end

  def name
    @element['NAME']
  end

  def name=(new_value)
    @element['NAME'] = new_value
  end

  def host
    @element['HOST']
  end

  def host=(new_value)
    @element['HOST'] = new_value
  end

  def stack
    if @element['ABAP_ENABLED'] == 'true' and @element['JAVA_ENABLED'] == 'true'
      :dual
    elsif @element['JAVA_ENABLED'] == 'true'
      :java
    else
      :abap
    end
  end

  def stack=(new_value)
    case new_value
    when :dual
      @element['ABAP_ENABLED'] = 'true'
      @element['JAVA_ENABLED'] = 'true'
    when :java
      @element['ABAP_ENABLED'] = 'false'
      @element['JAVA_ENABLED'] = 'true'
    else
      @element['ABAP_ENABLED'] = 'true'
      @element['JAVA_ENABLED'] = 'false'
    end
  end

  def ccms_mode
    if mode = @element['CCMS_STRICT_MODE'] and mode == 'true'
      :strict
    else
      :aggregated
    end
  end

  def ccms_mode=(new_value)
    case new_value
    when :strict
      @element['CCMS_STRICT_MODE'] = 'true'
    when :aggregated
      @element['CCMS_STRICT_MODE'] = 'false'
    end
  end

  def sid
    @element['SYSTEM_ID']
  end

  def sid=(new_value)
    @element['SYSTEM_ID'] = new_value
  end

  def client
    @element['ABAP_CLIENT_NUMBER']
  end

  def client=(new_value)
    @element['ABAP_CLIENT_NUMBER'] = new_value
  end

  def group
    @element['GROUP']
  end

  def group=(new_value)
    @element['GROUP'] = new_value
  end

  def ip
    if ips_element = @element['INSTANCE_IPS']
      ips_element.dup
    else
      []
    end
  end

  def ip=(new_value)
    if new_value.empty?
      @element.delete('INSTANCE_IPS')
    else
      @element['INSTANCE_IPS'] = new_value.dup
    end
  end

  def landscape
    if id = @element['PARENT_ID']
      if landscape = Puppet::Util::Agentil.landscapes[id.to_i]
        landscape
      else
        raise Puppet::Error, "Landscape with id=#{id} could not be found"
      end
    else
      raise Puppet::Error, 'System does not have a PARENT_ID attribute'
    end
  end

  def landscape=(new_value)
    new_landscape = case new_value
    when Puppet::Util::AgentilLandscape
      new_value
    when Fixnum
      Puppet::Util::Agentil.landscapes[new_value]
    when String
      Puppet::Util::Agentil.landscapes.values.find { |l| l.name == new_value }
    end

    raise Puppet::Error, "Landscape #{new_value} not found" unless new_landscape

    if landscape_id = @element['PARENT_ID']
      Puppet::Util::Agentil.landscapes[landscape_id.to_i].deassign_system id
    end
      
    new_landscape.assign_system id
    @element['PARENT_ID'] = new_landscape.id.to_s
  end

  def templates
    @template_ids.map do |id|
      if template = Puppet::Util::Agentil.templates[id]
        template
      else
        raise Puppet::Error, "Template with id=#{id} could not be found"
      end
    end
  end

  def templates=(new_values)
    if new_values.empty?
      @element.delete('TEMPLATES')
      @template_ids.clear
    else
      @template_ids = new_values.map do |new_value|
        template = case new_value
        when Puppet::Util::AgentilTemplate
          new_value
        when Fixnum
          Puppet::Util::Agentil.templates[new_value]
        when String
          Puppet::Util::Agentil.templates.values.find { |t| t.name == new_value }
        end

        raise Puppet::Error, "Template #{new_value} not found" unless template
        template.id
      end

      @element['TEMPLATES'] = @template_ids.dup
    end
  end

  def system_template
    if @system_template_id
      if template = Puppet::Util::Agentil.templates[@system_template_id]
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
      Puppet::Util::Agentil.templates[new_value]
    when String
      Puppet::Util::Agentil.templates.values.find { |t| t.name == new_value }
    end

    raise Puppet::Error, "Template #{new_value} not found" unless new_system_template


    @system_template_id = new_system_template.id
    @element['DEFAULT_TEMPLATE'] = @system_template_id.to_s
  end

  def user
    if @user_id
      if user = Puppet::Util::Agentil.users[@user_id]
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
      Puppet::Util::Agentil.users[new_value]
    when String
      Puppet::Util::Agentil.users.values.find { |u| u.name == new_value }
    end

    raise Puppet::Error, "Unable to find user #{new_value}" unless new_user

    @user_id = new_user.id
    @element['USER_PROFILE'] = @user_id.to_s
  end
end
