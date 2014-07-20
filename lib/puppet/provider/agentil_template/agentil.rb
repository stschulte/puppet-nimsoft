require 'puppet/util/agentil'

Puppet::Type.type(:agentil_template).provide(:agentil) do

  def self.instances
    instances = []
    Puppet::Util::Agentil.parse unless Puppet::Util::Agentil.parsed?
    Puppet::Util::Agentil.templates.each do |id, template|
      instances << new(:name => template.name, :ensure => :present, :agentil_template => template)
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
    new_template = Puppet::Util::Agentil.add_template
    new_template.name = resource[:name]
    new_template.system_template = resource[:system]
    new_template.jobs = resource[:jobs] if resource[:jobs]
    @property_hash[:agentil_template] = new_template
  end

  def destroy
    Puppet::Util::Agentil.del_template @property_hash[:agentil_template].id
    @property_hash.delete :agentil_template
  end

  def jobs
    @property_hash[:agentil_template].jobs
  end

  def jobs=(new_value)
    @property_hash[:agentil_template].jobs = new_value
  end

  def system
    @property_hash[:agentil_template].system_template
  end

  def system=(new_value)
    @property_hash[:agentil_template].system_template = new_value
  end

  def tablespace_used
    used = {}
    if job = @property_hash[:agentil_template].custom_jobs[166] and parameters = job['PARAMETERS']
      names = PSON.parse(parameters[0]["PARAMETER_VALUE"])
      values = PSON.parse(parameters[1]["PARAMETER_VALUE"])

      names.each_with_index do |tablespace, index|
        used[tablespace.intern] = values[index].to_i
      end
    end
    used
  end

  def tablespace_used=(new_value)
    if new_value.empty?
      @property_hash[:agentil_template].del_custom_job 166
    else
      job = @property_hash[:agentil_template].add_custom_job 166
      names = []
      values = []
      new_value.keys.sort.each do |tablespace|
        names  << tablespace.to_s
        values << new_value[tablespace]
      end
      job['PARAMETERS'] = [
        {
          'IDX'             => '0',
          'PARAMETER_VALUE' => names.to_pson
        },
        {
          'IDX'             => '1',
          'PARAMETER_VALUE' => values.to_pson
        }
      ]
    end
  end

  def expected_instances
    if job = @property_hash[:agentil_template].custom_jobs[177] and instances = job['Default']
      instances.map { |i| i['EXPECTED_INSTANCES'] }
    else
      []
    end
  end

  def expected_instances=(new_value)
    if new_value.empty?
      @property_hash[:agentil_template].del_custom_job 177
    else
      job = @property_hash[:agentil_template].add_custom_job 177

      job['Default'] = []
      new_value.each_with_index do |instance, index|
        job['Default'] << {
          'IDX'                => index.to_s,
          'MANDATORY'          => 'true',
          'SEVERITY'           => '5',
          'AUTOCLEAR'          => 'true',
          'EXPECTED_INSTANCES' => instance
        }
      end
    end
  end

  def flush
    Puppet::Util::Agentil.sync
  end
end
