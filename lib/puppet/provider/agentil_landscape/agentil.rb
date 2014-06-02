require 'puppet/util/agentil'

Puppet::Type.type(:agentil_landscape).provide(:agentil) do

  def self.instances
    instances = []
    Puppet::Util::Agentil.parse unless Puppet::Util::Agentil.parsed?
    Puppet::Util::Agentil.landscapes.each do |index, landscape|
      instances << new(:name => landscape.name, :ensure => :present, :agentil_landscape => landscape)
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
    new_landscape = Puppet::Util::Agentil.add_landscape
    new_landscape.name = resource[:name]
    new_landscape.sid = resource[:sid]
    new_landscape.company = resource[:company] if resource[:company]
    new_landscape.description = resource[:description] if resource[:description]
    @property_hash[:agentil_landscape] = new_landscape
  end

  def destroy
    Puppet::Util::Agentil.del_landscape @property_hash[:agentil_landscape].id
    @property_hash.delete :agentil_landscape
  end

  [:sid, :description, :company].each do |prop|
    define_method(prop) do
      @property_hash[:agentil_landscape].send(prop)
    end
    define_method("#{prop}=") do |new_value|
      @property_hash[:agentil_landscape].send("#{prop}=", new_value)
    end
  end

  def flush
    Puppet::Util::Agentil.sync
  end
end
