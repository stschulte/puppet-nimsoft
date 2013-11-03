require 'puppet/util/agentil_template'

Puppet::Type.type(:agentil_template).provide(:agentil) do

  def self.instances
    instances = []
    Puppet::Util::AgentilTemplate.templates.each do |name, template|
      instances << new(:name => name, :ensure => :present, :template => template)
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
    raise Puppet::Error, 'Unable to create a new template without a system property'  unless resource[:system]
    new_template = Puppet::Util::AgentilTemplate.add name
    new_template.system = resource[:system]
    new_template.instances = resource[:instances] if resource[:instances]
    new_template.jobs = resource[:jobs] if resource[:jobs]
    new_template.monitors = resource[:monitors] if resource[:monitors]
    @property_hash[:template] = new_template
  end

  def destroy
    Puppet::Util::AgentilTemplate.del name
  end

  [:system, :instances, :jobs, :monitors].each do |prop|
    define_method(prop) do
      @property_hash[:template].send(prop)
    end
    define_method("#{prop}=") do |new_value|
      @property_hash[:template].send("#{prop}=", new_value)
    end
  end

  def flush
    Puppet::Util::AgentilTemplate.sync
  end
end
