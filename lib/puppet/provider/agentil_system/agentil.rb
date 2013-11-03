require 'puppet/util/agentil_system'

Puppet::Type.type(:agentil_system).provide(:agentil) do

  def self.instances
    instances = []
    Puppet::Util::AgentilSystem.systems.each do |name, system|
      instances << new(:name => name, :ensure => :present, :system => system)
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

    new_system = Puppet::Util::AgentilSystem.add name
    new_system.sid = resource[:sid]
    new_system.host = resource[:host]
    new_system.ip = resource[:ip] if resource[:ip]
    new_system.stack = resource[:stack]
    new_system.user = resource[:user] if resource[:user]
    new_system.client = resource[:client] if resource[:client]
    new_system.group = resource[:group] if resource[:group]
    new_system.landscape = resource[:landscape]
    new_system.default = resource[:default] if resource[:default]
    new_system.templates = resource[:templates] if resource[:templates]
  end

  def destroy
    Puppet::Util::AgentilSystem.del name
  end

  [:sid, :host, :ip, :stack, :user, :client, :group, :landscape, :default, :templates].each do |prop|
    define_method(prop) do
      @property_hash[:system].send(prop)
    end
    define_method("#{prop}=") do |new_value|
      @property_hash[:system].send("#{prop}=", new_value)
    end
  end

  def flush
    Puppet::Util::AgentilSystem.sync
  end

end
