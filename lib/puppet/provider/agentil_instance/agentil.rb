require 'puppet/util/agentil_job177'
require 'puppet/util/nimsoft_config'

Puppet::Type.type(:agentil_instance).provide(:agentil) do

  def self.filename
    '/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg'
  end

  def self.number_to_severity(number)
    [ :clear, :info, :warning, :minor, :major, :critical ][number]
  end

  def self.severity_to_number(sev)
    [ :clear, :info, :warning, :minor, :major, :critical ].index sev
  end

  def self.instances
    instances = []
    Puppet::Util::AgentilJob177.jobs.values.each do |job|
      job.instances.each do |instance|
        instances << new(
          :name        => instance[:name],
          :ensure      => :present,
          :job         => job,
          :criticality => number_to_severity(instance[:criticality].to_i),
          :autoclear   => instance[:autoclear].intern,
          :mandatory   => instance[:mandatory].intern
        )
      end
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
    unless resource[:template]
      raise Puppet::Error, "Unable to create an instance without a template"
    end

    Puppet::Util::AgentilTemplate.templates.each do |name, template|
      if name == resource[:template]
        @property_hash[:job] = Puppet::Util::AgentilJob177.add(name, template)
        break
      end
    end

    raise Puppet::Error, "Unable to find template #{resource[:name]}" if job.nil?

    args ={}
    args[:criticality] = self.class.severity_to_number(resource[:criticality]).to_s if resource[:criticality]
    args[:autoclear] = resource[:autoclear].to_s if resource[:autoclear]
    args[:mandatory] = resource[:mandatory].to_s if resource[:mandatory]

    job.add_instance(name, args)
  end

  def destroy
    if job
      Puppet::Util::AgentilJob177.del job.name
    end
  end

  def job
    @property_hash[:job]
  end

  def template
    job.template.name
  end

  def template=(new_value)
    new_job = nil

    Puppet::Util::AgentilTemplate.templates.each do |name, template|
      if name == new_value
        new_job = Puppet::Util::AgentilJob177.add(name, template)
        break
      end
    end

    raise Puppet::Error, "Unable to find template #{new_value}" unless new_job

    if current_instance = job.del_instance(name)
      if job.instances.empty?
        Puppet::Util::AgentilJob177.del job.name
      end
      new_job.add_instance(name, current_instance)
      @property_hash[:job] = new_job
    end
  end

  def criticality
    get(:criticality)
  end

  def criticality=(new_value)
    job.mod_instance(name, :criticality => self.class.severity_to_number(new_value))
    @property_hash[:criticality] = new_value
  end

  def autoclear
    get(:autoclear)
  end

  def autoclear=(new_value)
    job.mod_instance(name, :autoclear => new_value.to_s)
    @property_hash[:autoclear] = new_value
  end

  def mandatory
    get(:mandatory)
  end

  def mandatory=(new_value)
    job.mod_instance(name, :mandatory => new_value.to_s)
    @property_hash[:mandatory] = new_value
  end

  def flush
    Puppet::Util::NimsoftConfig.flush(self.class.filename)
  end

end
