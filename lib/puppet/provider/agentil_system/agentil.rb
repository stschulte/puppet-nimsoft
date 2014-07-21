require 'puppet/util/agentil'

Puppet::Type.type(:agentil_system).provide(:agentil) do

  def self.instances
    instances = []
    Puppet::Util::Agentil.parse unless Puppet::Util::Agentil.parsed?
    Puppet::Util::Agentil.systems.each do |id, system|
      instances << new(:name => system.name, :ensure => :present, :agentil_system => system)
    end
    instances
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def exists?
    get(:ensure) != :absent
  end

  def create
    [ :sid, :host, :stack, :landscape ].each do |mandatory_property|
      raise Puppet::Error, "Cannot create system with no #{mandatory_property}" unless resource[mandatory_property]
    end

    system_template = nil
    if template_name = resource[:system_template]
      system_template = Puppet::Util::Agentil.templates.values.find { |t| t.name == template_name }
      if system_template.nil?
        raise Puppet::Error, "Template #{template_name.inspect} not found"
      elsif not system_template.system_template?
        raise Puppet::Error, "Template #{template_name.inspect} is not a system template"
      end
    end

    templates = nil
    if template_names = resource[:templates]
      template_names.each do |template_name|
        template = Puppet::Util::Agentil.templates.values.find { |t| t.name == template_name }
        if template.nil?
          raise Puppet::Error, "Template #{template_name.inspect} not found"
        elsif template.system_template?
          raise Puppet::Error, "Template #{template_name.inspect} is a system template"
        end
        templates ||= []
        templates << template
      end
    end

    user = nil
    if user_name = resource[:user]
      unless user = Puppet::Util::Agentil.users.values.find { |t| t.name == user_name }
        raise Puppet::Error, "User #{user_name.inspect} not found"
      end
    end

    new_system = Puppet::Util::Agentil.add_system
    new_system.name = resource[:name]
    new_system.sid = resource[:sid]
    new_system.host = resource[:host]
    new_system.ip = resource[:ip] if resource[:ip]
    new_system.stack = resource[:stack]
    new_system.ccms_mode = resource[:ccms_mode] unless resource[:ccms_mode].nil?
    new_system.user = user unless user.nil?
    new_system.client = resource[:client] if resource[:client]
    new_system.group = resource[:group] if resource[:group]
    new_system.landscape = resource[:landscape]
    new_system.system_template = system_template unless system_template.nil?
    new_system.templates = templates unless templates.nil?
    @property_hash[:agentil_system] = new_system
  end

  def destroy
    Puppet::Util::Agentil.del_system @property_hash[:agentil_system].id
    @property_hash.delete :agentil_system
  end

  [:sid, :host, :ip, :stack, :client, :group, :ccms_mode ].each do |prop|
    define_method(prop) do
      @property_hash[:agentil_system].send(prop)
    end
    define_method("#{prop}=") do |new_value|
      @property_hash[:agentil_system].send("#{prop}=", new_value)
    end
  end

  def landscape
    if landscape = @property_hash[:agentil_system].landscape
      landscape.name
    end
  end

  def system_template
    if template = @property_hash[:agentil_system].system_template
      template.name
    end
  end

  def templates
    if templates = @property_hash[:agentil_system].templates
      templates.map(&:name)
    end
  end

  def user
    if user = @property_hash[:agentil_system].user
      user.name
    end
  end

  def landscape=(new_value)
    if landscape = Puppet::Util::Agentil.landscapes.values.find { |t| t.name == new_value }
      @property_hash[:agentil_system].landscape = landscape
    else
      raise Puppet::Error, "Landscape #{new_value.inspect} not found"
    end
  end

  def system_template=(new_value)
    if template = Puppet::Util::Agentil.templates.values.find { |t| t.name == new_value }
      raise Puppet::Error, "Template #{new_value.inspect} is not a system template" unless template.system_template?
      @property_hash[:agentil_system].system_template = template
    else
      raise Puppet::Error, "Template #{new_value.inspect} not found"
    end
  end

  def templates=(new_values)
    new_templates = []
    new_values.each do |new_value|
      if template = Puppet::Util::Agentil.templates.values.find { |t| t.name == new_value }
        raise Puppet::Error, "Template #{new_value}.inspect is a system template" if template.system_template?
        new_templates << template
      else
        raise Puppet::Error, "Template #{new_value.inspect} not found"
      end
    end

    @property_hash[:agentil_system].templates = new_templates
  end

  def user=(new_value)
    if user = Puppet::Util::Agentil.users.values.find { |t| t.name == new_value }
      @property_hash[:agentil_system].user = user
    else
      raise Puppet::Error, "User #{new_value.inspect} not found"
    end
  end

  def flush
    Puppet::Util::Agentil.sync
  end
end
