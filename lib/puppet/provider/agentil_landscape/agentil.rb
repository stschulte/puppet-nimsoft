require 'puppet/util/agentil_landscape'

Puppet::Type.type(:agentil_landscape).provide(:agentil) do

  def self.instances
    instances = []
    Puppet::Util::AgentilLandscape.landscapes.each do |name, landscape|
      instances << new(:name => name, :ensure => :present, :landscape => landscape)
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
    raise Puppet::Error, "Unable to create a new landscape with no sid beeing specified" unless resource[:sid]
    new_landscape = Puppet::Util::AgentilLandscape.add name
    new_landscape.sid = resource[:sid]
    new_landscape.company = resource[:company] if resource[:company]
    new_landscape.description = resource[:description] if resource[:description]
    @property_hash[:landscape] = new_landscape
  end

  def destroy
    Puppet::Util::AgentilLandscape.del name
  end

  [:sid, :description, :company].each do |prop|
    define_method(prop) do
      @property_hash[:landscape].send(prop)
    end
    define_method("#{prop}=") do |new_value|
      @property_hash[:landscape].send("#{prop}=", new_value)
    end
  end

  def flush
    Puppet::Util::AgentilLandscape.sync
  end

end
